//
//  ContentView.swift
//  TVHomeRun
//
//  Root content view that handles navigation based on setup state
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var userSettings: UserSettings
    @State private var showSetup = false

    var body: some View {
        Group {
            if userSettings.serverURL.isEmpty || showSetup {
                ServerSetupView(userSettings: userSettings)
            } else {
                NavigationStack {
                    ShowsListView(apiClient: APIClient(baseURL: userSettings.serverURL))
                }
            }
        }
        .onAppear {
            // Show setup if no URL is configured
            showSetup = userSettings.serverURL.isEmpty
        }
    }
}
