//
//  MainTabView.swift
//  TVHomeRun
//
//  Top-level tab bar: Recordings, Live TV, Guide, Settings
//

import SwiftUI

enum AppTab: Hashable {
    case recordings
    case liveTV
    case guide
    case settings
}

struct MainTabView: View {
    @StateObject private var apiClient: APIClient
    @State private var selection: AppTab = .recordings

    init(serverURL: String) {
        _apiClient = StateObject(wrappedValue: APIClient(baseURL: serverURL))
    }

    var body: some View {
        TabView(selection: $selection) {
            Tab("Recordings", systemImage: "film.stack", value: .recordings) {
                NavigationStack {
                    ShowsListView(apiClient: apiClient)
                }
            }
            Tab("Live TV", systemImage: "tv", value: .liveTV) {
                NavigationStack {
                    LiveChannelsView(apiClient: apiClient)
                }
            }
            Tab("Guide", systemImage: "calendar", value: .guide) {
                NavigationStack {
                    GuideView(apiClient: apiClient)
                }
            }
            Tab("Settings", systemImage: "gearshape", value: .settings) {
                NavigationStack {
                    SettingsView(apiClient: apiClient)
                }
            }
        }
        // One shared connection alert for every screen that uses the client.
        .alert("Connection Error", isPresented: $apiClient.showErrorAlert) {
            Button("OK") { apiClient.clearError() }
        } message: {
            Text(apiClient.error?.localizedDescription ?? "The server could not be reached.")
        }
    }
}
