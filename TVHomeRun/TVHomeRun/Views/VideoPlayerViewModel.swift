//
//  VideoPlayerViewModel.swift
//  TVHomeRun
//
//  ViewModel for managing video playback state and controls
//

import Foundation
import AVKit
import Combine

@MainActor
class VideoPlayerViewModel: ObservableObject {
    @Published var player: AVPlayer
    @Published var isPlaying = false
    @Published var isLoading = true
    @Published var showControls = true
    @Published var progress: Double = 0
    @Published var currentTimeString = "0:00"
    @Published var durationString = "0:00"
    @Published var errorMessage: String?

    @Published var currentEpisode: Episode
    private let allEpisodes: [Episode]

    private var timeObserver: Any?
    private var controlsTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    var hasNextEpisode: Bool {
        guard let currentIndex = allEpisodes.firstIndex(where: { $0.id == currentEpisode.id }) else {
            return false
        }
        return currentIndex < allEpisodes.count - 1
    }

    var hasPreviousEpisode: Bool {
        guard let currentIndex = allEpisodes.firstIndex(where: { $0.id == currentEpisode.id }) else {
            return false
        }
        return currentIndex > 0
    }

    init(episode: Episode, allEpisodes: [Episode]) {
        self.currentEpisode = episode
        self.allEpisodes = allEpisodes
        self.player = AVPlayer()

        setupPlayer(with: episode)
        setupControlsTimer()
    }

    private func setupPlayer(with episode: Episode) {
        isLoading = true
        errorMessage = nil

        print("Attempting to play URL: \(episode.playUrl)")
        print("Command URL: \(episode.cmdUrl)")

        guard let url = URL(string: episode.playUrl) else {
            errorMessage = "Invalid video URL: \(episode.playUrl)"
            isLoading = false
            return
        }

        print("Valid URL created: \(url)")

        // Create player item directly - native player will handle format detection
        let playerItem = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: playerItem)

        // Set up time observer
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.updateProgress()
        }

        // Observe player item status
        playerItem.publisher(for: \.status)
            .sink { [weak self] status in
                Task { @MainActor in
                    switch status {
                    case .readyToPlay:
                        self?.isLoading = false
                        // Seek to resume position if available
                        if let resumePosition = episode.resumePosition, resumePosition > 0 {
                            let seekTime = CMTime(seconds: Double(resumePosition), preferredTimescale: 1)
                            self?.player.seek(to: seekTime)
                        }
                        self?.player.play()
                        self?.isPlaying = true
                    case .failed:
                        if let error = playerItem.error {
                            print("Player item failed with error: \(error)")
                            self?.errorMessage = "Failed to load video: \(error.localizedDescription)"
                        } else {
                            print("Player item failed with unknown error")
                            self?.errorMessage = "Failed to load video: Unknown error"
                        }
                        self?.isLoading = false
                    default:
                        break
                    }
                }
            }
            .store(in: &cancellables)

        // Observe playback end
        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)
            .sink { [weak self] _ in
                Task { @MainActor in
                    // Auto-play next episode
                    if self?.hasNextEpisode == true {
                        self?.playNextEpisode()
                    }
                }
            }
            .store(in: &cancellables)
    }

    private func updateProgress() {
        let currentTime = player.currentTime().seconds
        let duration = player.currentItem?.duration.seconds ?? 0

        if duration.isFinite && duration > 0 {
            progress = currentTime / duration
            currentTimeString = formatTime(currentTime)
            durationString = formatTime(duration)
        }
    }

    private func formatTime(_ timeInSeconds: Double) -> String {
        guard timeInSeconds.isFinite else { return "0:00" }
        let totalSeconds = Int(timeInSeconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    func togglePlayPause() {
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying.toggle()
        resetControlsTimer()
    }

    func skipForward() {
        let currentTime = player.currentTime()
        let newTime = CMTimeAdd(currentTime, CMTime(seconds: 30, preferredTimescale: 1))
        player.seek(to: newTime)
        resetControlsTimer()
    }

    func skipBackward() {
        let currentTime = player.currentTime()
        let newTime = CMTimeSubtract(currentTime, CMTime(seconds: 15, preferredTimescale: 1))
        player.seek(to: newTime)
        resetControlsTimer()
    }

    func playNextEpisode() {
        guard let currentIndex = allEpisodes.firstIndex(where: { $0.id == currentEpisode.id }),
              currentIndex < allEpisodes.count - 1 else {
            return
        }

        let nextEpisode = allEpisodes[currentIndex + 1]
        currentEpisode = nextEpisode

        // Remove old observers
        if let timeObserver = timeObserver {
            player.removeTimeObserver(timeObserver)
        }
        cancellables.removeAll()

        setupPlayer(with: nextEpisode)
        resetControlsTimer()
    }

    func playPreviousEpisode() {
        guard let currentIndex = allEpisodes.firstIndex(where: { $0.id == currentEpisode.id }),
              currentIndex > 0 else {
            return
        }

        let previousEpisode = allEpisodes[currentIndex - 1]
        currentEpisode = previousEpisode

        // Remove old observers
        if let timeObserver = timeObserver {
            player.removeTimeObserver(timeObserver)
        }
        cancellables.removeAll()

        setupPlayer(with: previousEpisode)
        resetControlsTimer()
    }

    func toggleControls() {
        showControls.toggle()
        if showControls {
            resetControlsTimer()
        } else {
            controlsTimer?.invalidate()
        }
    }

    private func setupControlsTimer() {
        resetControlsTimer()
    }

    private func resetControlsTimer() {
        controlsTimer?.invalidate()
        controlsTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            Task { @MainActor in
                if self?.isPlaying == true {
                    self?.showControls = false
                }
            }
        }
    }

    func close() {
        player.pause()
        if let timeObserver = timeObserver {
            player.removeTimeObserver(timeObserver)
        }
        controlsTimer?.invalidate()
    }
}
