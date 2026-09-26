//
//  NativeVideoPlayer.swift
//  TVHomeRun
//
//  AVPlayerViewController wrapper with the system transport controls
//

import SwiftUI
import AVKit

struct NativeVideoPlayer: UIViewControllerRepresentable {
    let player: AVPlayer

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = true
        controller.videoGravity = .resizeAspect
        return controller
    }

    func updateUIViewController(_ controller: AVPlayerViewController, context: Context) {
        if controller.player !== player {
            controller.player = player
        }
    }
}

/// Full-screen error state shown over a player that failed to load.
struct PlaybackErrorView: View {
    let message: String
    let onClose: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Playback Failed", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button("Close", action: onClose)
        }
    }
}
