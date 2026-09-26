//
//  SettingsView.swift
//  TVHomeRun
//
//  Settings tab
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var apiClient: APIClient

    var body: some View {
        ServerConnectionForm(showsAppInfo: true) { url in
            apiClient.updateBaseURL(url)
        }
        .navigationTitle("Settings")
    }
}
