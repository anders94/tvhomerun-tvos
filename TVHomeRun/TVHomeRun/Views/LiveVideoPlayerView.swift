//
//  LiveVideoPlayerView.swift
//  TVHomeRun
//
//  Plays a live channel with the system player controls
//

import SwiftUI

struct LiveVideoPlayerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var playerViewModel: LiveVideoPlayerViewModel

    init(channel: Channel, apiClient: APIClient) {
        _playerViewModel = StateObject(
            wrappedValue: LiveVideoPlayerViewModel(channel: channel, apiClient: apiClient)
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
