//
//  VideoPlayerViewModel.swift
//  TVHomeRun
//
//  Recorded playback: resume position, periodic progress saves, auto-advance
//

import Foundation
import AVKit
import Combine

@MainActor
class VideoPlayerViewModel: ObservableObject {
    @Published var player = AVPlayer()
    @Published var errorMessage: String?
    @Published private(set) var currentEpisode: Episode

    /// Episodes in the order they were displayed; "next" follows this order.
    private let allEpisodes: [Episode]
    private let apiClient: APIClient

    private var statusObserver: AnyCancellable?
    private var endObserver: AnyCancellable?
    private var progressSaveObserver: Any?
    private var lastSavedPosition = 0
    /// Once an episode counts as watched it stays watched for this session,
    /// so seeking back to rewatch a bit doesn't clear the flag.
    private var currentEpisodeWatched: Bool
    private var hasSetup = false

    init(episode: Episode, allEpisodes: [Episode], apiClient: APIClient) {
        self.currentEpisode = episode
        self.allEpisodes = allEpisodes
        self.apiClient = apiClient
        self.currentEpisodeWatched = episode.isWatched
    }

    var hasNextEpisode: Bool {
        guard let index = allEpisodes.firstIndex(where: { $0.id == currentEpisode.id }) else { return false }
        return index < allEpisodes.count - 1
    }

    func setup() {
        guard !hasSetup else { return }
        hasSetup = true
        setupPlayer(with: currentEpisode)
    }

    func playNextEpisode() {
        guard let index = allEpisodes.firstIndex(where: { $0.id == currentEpisode.id }),
              index < allEpisodes.count - 1 else { return }
        let next = allEpisodes[index + 1]
        currentEpisode = next
        currentEpisodeWatched = next.isWatched
        lastSavedPosition = 0
        setupPlayer(with: next)
    }

    func close() {
        Task { await saveProgressToServer() }
        player.pause()
        cleanup()
    }

    // MARK: - Player setup

    private func setupPlayer(with episode: Episode) {
        errorMessage = nil
        cleanup()

        guard let url = URL(string: episode.playUrl) else {
            errorMessage = "Invalid video URL: \(episode.playUrl)"
            return
        }

        let playerItem = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: playerItem)

        // Save progress every 30 seconds while playing.
        let saveInterval = CMTime(seconds: 30, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        progressSaveObserver = player.addPeriodicTimeObserver(forInterval: saveInterval, queue: .main) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                await self.saveProgressToServer()
            }
        }

        statusObserver = playerItem.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self else { return }
                switch status {
                case .readyToPlay:
                    if let resume = episode.resumePosition, resume > 0 {
                        let seekTime = CMTime(seconds: Double(resume), preferredTimescale: 1)
                        self.player.seek(to: seekTime) { _ in
                            Task { @MainActor in self.player.play() }
                        }
                    } else {
                        self.player.play()
                    }
                case .failed:
                    let reason = playerItem.error?.localizedDescription ?? "Unknown error"
                    self.errorMessage = "Failed to load video: \(reason)"
                default:
                    break
                }
            }

        endObserver = NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: playerItem)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                Task { @MainActor in
                    await self.markAsWatched()
                    if self.hasNextEpisode {
                        self.playNextEpisode()
                    }
                }
            }
    }

    private func cleanup() {
        if let progressSaveObserver {
            player.removeTimeObserver(progressSaveObserver)
            self.progressSaveObserver = nil
        }
        statusObserver?.cancel()
        statusObserver = nil
        endObserver?.cancel()
        endObserver = nil
    }

    // MARK: - Progress

    private func saveProgressToServer() async {
        let seconds = player.currentTime().seconds
        let duration = player.currentItem?.duration.seconds ?? 0
        guard seconds.isFinite, duration.isFinite, duration > 0 else { return }
        let currentTime = Int(seconds)

        // Skip tiny moves.
        guard currentTime > 0, abs(currentTime - lastSavedPosition) >= 5 else { return }

        // Judge "watched" against the scheduled length the backend uses, not
        // the file's: recordings run ~30s long, which would push the 90% mark
        // past where people usually stop during the credits.
        let scheduledDuration = currentEpisode.duration > 0 ? currentEpisode.duration : Int(duration)
        if Episode.isMostlyWatched(position: currentTime, duration: scheduledDuration) {
            currentEpisodeWatched = true
        }

        do {
            try await apiClient.updateEpisodeProgress(
                episodeId: currentEpisode.id,
                position: currentTime,
                watched: currentEpisodeWatched
            )
            lastSavedPosition = currentTime
        } catch {
            // Never interrupt playback over a failed progress save.
        }
    }

    private func markAsWatched() async {
        currentEpisodeWatched = true
        let duration = Int(player.currentItem?.duration.seconds ?? 0)
        try? await apiClient.updateEpisodeProgress(episodeId: currentEpisode.id, position: duration, watched: true)
    }
}
