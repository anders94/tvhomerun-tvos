//
//  VideoPlayerView.swift
//  TVHomeRun
//
//  Plays a recorded episode with the system player controls
//

import SwiftUI

struct VideoPlayerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var playerViewModel: VideoPlayerViewModel

    init(episode: Episode, allEpisodes: [Episode], apiClient: APIClient) {
        _playerViewModel = StateObject(
            wrappedValue: VideoPlayerViewModel(episode: episode, allEpisodes: allEpisodes, apiClient: apiClient)
        )
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            NativeVideoPlayer(player: playerViewModel.player)
                .ignoresSafeArea()
                .onAppear { playerViewModel.setup() }
                .onDisappear { playerViewModel.close() }

            if let error = playerViewModel.errorMessage {
                PlaybackErrorView(message: error) { dismiss() }
            }
        }
    }
}
