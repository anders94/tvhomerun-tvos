//
//  ServerSetupView.swift
//  TVHomeRun
//
//  View for configuring the server URL
//

import SwiftUI

struct ServerSetupView: View {
    @EnvironmentObject var userSettings: UserSettings
    @StateObject private var apiClient: APIClient
    @State private var urlInput: String
    @State private var isValidating = false
    @State private var validationError: String?
    var onSettingsSaved: (() -> Void)? = nil

    init(userSettings: UserSettings, onSettingsSaved: (() -> Void)? = nil) {
        _urlInput = State(initialValue: userSettings.serverURL.isEmpty ? "http://" : userSettings.serverURL)
        _apiClient = StateObject(wrappedValue: APIClient(baseURL: userSettings.serverURL))
        self.onSettingsSaved = onSettingsSaved
    }

    var body: some View {
        ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 40) {
                    // Logo and title
                    VStack(spacing: 20) {
                        Image(systemName: "play.tv.fill")
                            .font(.system(size: 120))
                            .foregroundColor(.white)

                        Text("TV HomeRun")
                            .font(.system(size: 60, weight: .bold))
                            .foregroundColor(.white)

                        Text("Stream your recorded content")
                            .font(.system(size: 30))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(.top, 60)

                    // URL Input Card
                    VStack(spacing: 30) {
                        Text("Enter Server URL")
                            .font(.system(size: 36, weight: .semibold))
                            .foregroundColor(.white)

                        TextField("http://192.168.1.100:3000", text: $urlInput)
                            .textFieldStyle(.plain)
                            .font(.system(size: 32))
                            .padding(20)
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(10)
                            .frame(maxWidth: 900)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)

                        if let error = validationError {
                            Text(error)
                                .font(.system(size: 24))
                                .foregroundColor(.red)
                                .padding(.horizontal, 40)
                        }

                        // Accept button
                        Button(action: validateAndConnect) {
                            HStack {
                                if isValidating {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                        .tint(.white)
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 28))
                                }
                                Text(isValidating ? "Connecting..." : "Accept")
                                    .font(.system(size: 32, weight: .semibold))
                            }
                            .frame(width: 300, height: 80)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(isValidating || urlInput.isEmpty)
                        .buttonStyle(.card)
                    }
                    .padding(.horizontal, 60)

                    Spacer()
                }
            }
    }

    private func validateAndConnect() {
        validationError = nil
        isValidating = true

        // Clean up URL
        var cleanURL = urlInput.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleanURL.hasPrefix("http://") && !cleanURL.hasPrefix("https://") {
            cleanURL = "http://" + cleanURL
        }
        // Remove trailing slash
        if cleanURL.hasSuffix("/") {
            cleanURL = String(cleanURL.dropLast())
        }

        apiClient.updateBaseURL(cleanURL)

        Task {
            do {
                let health = try await apiClient.checkHealth()
                if health.isHealthy {
                    await MainActor.run {
                        userSettings.saveServerURL(cleanURL)
                        isValidating = false
                        onSettingsSaved?()
                    }
                } else {
                    await MainActor.run {
                        validationError = "Server is not healthy: \(health.status)"
                        isValidating = false
                    }
                }
            } catch {
                await MainActor.run {
                    validationError = "Unable to connect: \(error.localizedDescription)"
                    isValidating = false
                }
            }
        }
    }
}
