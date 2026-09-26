//
//  ServerSetupView.swift
//  TVHomeRun
//
//  First-run screen shown until a server answers the health check
//

import SwiftUI

struct ServerSetupView: View {
    var onConnected: () -> Void

    var body: some View {
        VStack(spacing: 40) {
            VStack(spacing: 16) {
                Image(systemName: "play.tv.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.tint)
                Text("TVHomeRun")
                    .font(.title)
                Text("Connect to your tvhomerun-backend server to get started.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 60)

            ServerConnectionForm { _ in onConnected() }
                .frame(maxWidth: 1100)
        }
        .padding(.horizontal, 60)
    }
}
