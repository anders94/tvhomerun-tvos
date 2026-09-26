//
//  ContentView.swift
//  TVHomeRun
//
//  Root view: probes the configured server, then shows setup or the main tabs
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var userSettings: UserSettings
    @State private var launchState: LaunchState = .checking

    private enum LaunchState {
        case checking
        case needsSetup
        case ready
    }

    var body: some View {
        Group {
            switch launchState {
            case .checking:
                ProgressView("Connecting…")
            case .needsSetup:
                ServerSetupView { launchState = .ready }
            case .ready:
                MainTabView(serverURL: userSettings.serverURL)
            }
        }
        .task { await checkInitialConnectivity() }
    }

    private func checkInitialConnectivity() async {
        guard !userSettings.serverURL.isEmpty else {
            launchState = .needsSetup
            return
        }

        let probe = APIClient(baseURL: userSettings.serverURL)
        if let health = try? await probe.checkHealth(), health.isHealthy {
            launchState = .ready
        } else {
            launchState = .needsSetup
        }
    }
}
