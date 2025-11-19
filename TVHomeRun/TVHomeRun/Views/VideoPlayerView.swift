//
//  VideoPlayerView.swift
//  TVHomeRun
//
//  Custom video player with scrubbing and skip controls
//

import SwiftUI
import AVKit

struct VideoPlayerView: View {
    @Environment(\.dismiss) var dismiss
    let episode: Episode
    let allEpisodes: [Episode]

    @StateObject private var playerViewModel: VideoPlayerViewModel

    init(episode: Episode, allEpisodes: [Episode]) {
        self.episode = episode
        self.allEpisodes = allEpisodes
        _playerViewModel = StateObject(wrappedValue: VideoPlayerViewModel(episode: episode, allEpisodes: allEpisodes))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Use native AVPlayerViewController with built-in controls for better format support
            NativeVideoPlayer(player: playerViewModel.player)
                .ignoresSafeArea()
                .onAppear {
                    playerViewModel.setup()
                }
                .onDisappear {
                    playerViewModel.close()
                }

            // Show custom overlay only for errors and loading
            if false && playerViewModel.showControls {
                VStack {
                    // Top bar with episode info
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(episode.seriesTitle)
                                .font(.system(size: 32, weight: .semibold))
                            Text(episode.episodeNumber)
                                .font(.system(size: 24))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        Spacer()
                        Button(action: {
                            playerViewModel.close()
                            dismiss()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 60)
                    .padding(.top, 40)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.black.opacity(0.7), Color.clear]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    Spacer()

                    // Bottom controls
                    VStack(spacing: 20) {
                        // Progress bar
                        HStack(spacing: 20) {
                            Text(playerViewModel.currentTimeString)
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.white)
                                .monospacedDigit()

                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    // Background track
                                    Rectangle()
                                        .fill(Color.white.opacity(0.3))
                                        .frame(height: 8)

                                    // Progress
                                    Rectangle()
                                        .fill(Color.white)
                                        .frame(width: geometry.size.width * playerViewModel.progress, height: 8)
                                }
                                .cornerRadius(4)
                            }
                            .frame(height: 8)

                            Text(playerViewModel.durationString)
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.white)
                                .monospacedDigit()
                        }
                        .padding(.horizontal, 60)

                        // Playback controls
                        HStack(spacing: 50) {
                            // Previous episode
                            Button(action: {
                                playerViewModel.playPreviousEpisode()
                            }) {
                                Image(systemName: "backward.end.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(playerViewModel.hasPreviousEpisode ? .white : .gray)
                            }
                            .disabled(!playerViewModel.hasPreviousEpisode)

                            // Skip backward 15s
                            Button(action: {
                                playerViewModel.skipBackward()
                            }) {
                                Image(systemName: "gobackward.15")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white)
                            }

                            // Play/Pause
                            Button(action: {
                                playerViewModel.togglePlayPause()
                            }) {
                                Image(systemName: playerViewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                    .font(.system(size: 80))
                                    .foregroundColor(.white)
                            }

                            // Skip forward 30s
                            Button(action: {
                                playerViewModel.skipForward()
                            }) {
                                Image(systemName: "goforward.30")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white)
                            }

                            // Next episode
                            Button(action: {
                                playerViewModel.playNextEpisode()
                            }) {
                                Image(systemName: "forward.end.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(playerViewModel.hasNextEpisode ? .white : .gray)
                            }
                            .disabled(!playerViewModel.hasNextEpisode)
                        }
                        .padding(.bottom, 40)
                    }
                    .padding(.bottom, 60)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.7)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
            }

            // Error message
            if let error = playerViewModel.errorMessage {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.red)
                    Text(error)
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 100)
                    Button("Close") {
                        dismiss()
                    }
                    .font(.system(size: 24))
                    .padding(.horizontal, 40)
                    .padding(.vertical, 15)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
        }
    }
}

// Native AVPlayer wrapper with built-in controls
struct NativeVideoPlayer: UIViewControllerRepresentable {
    let player: AVPlayer

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = true
        controller.videoGravity = .resizeAspect
        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        // Only update if player instance changed
        if uiViewController.player !== player {
            uiViewController.player = player
        }
    }
}

// Custom AVPlayer wrapper (keeping for reference)
struct CustomVideoPlayer: UIViewControllerRepresentable {
    let player: AVPlayer

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false // We'll use custom controls
        controller.videoGravity = .resizeAspect
        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        if uiViewController.player !== player {
            uiViewController.player = player
        }
    }
}
