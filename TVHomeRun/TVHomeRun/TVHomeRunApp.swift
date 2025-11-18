//
//  TVHomeRunApp.swift
//  TVHomeRun
//
//  Main app entry point
//

import SwiftUI

@main
struct TVHomeRunApp: App {
    @StateObject private var userSettings = UserSettings()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(userSettings)
        }
    }
}
