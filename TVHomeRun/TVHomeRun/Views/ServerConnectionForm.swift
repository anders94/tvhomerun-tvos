//
//  ServerConnectionForm.swift
//  TVHomeRun
//
//  Server URL entry and validation, shared by first-run setup and Settings
//

import SwiftUI

struct ServerConnectionForm: View {
    @EnvironmentObject private var userSettings: UserSettings
    var showsAppInfo = false
    var onConnected: (String) -> Void

    @State private var urlInput = ""
    @State private var status: Status = .idle

    private enum Status: Equatable {
        case idle
        case checking
        case connected
        case failed(String)
    }

    var body: some View {
        Form {
            Section {
                TextField("Server URL", text: $urlInput, prompt: Text("http://192.168.1.100:3000"))
                    .keyboardType(.URL)
                    .textContentType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onSubmit { Task { await connect() } }

                Button {
                    Task { await connect() }
                } label: {
                    if status == .checking {
                        Label {
                            Text("Connecting…")
                        } icon: {
                            ProgressView()
                        }
                    } else {
                        Text("Connect")
                    }
                }
                .disabled(!canConnect)
            } header: {
                Text("Server")
            } footer: {
                Text("Enter the address of your tvhomerun-backend server, including the port.")
            }

            Section("Status") {
                statusRow
            }

            if showsAppInfo {
                Section("About") {
                    LabeledContent("Version", value: appVersion)
                }
            }
        }
        .onAppear {
            if urlInput.isEmpty {
                urlInput = userSettings.serverURL.isEmpty ? "http://" : userSettings.serverURL
            }
        }
    }

    private var canConnect: Bool {
        status != .checking && !normalizedURL.isEmpty
    }

    @ViewBuilder
    private var statusRow: some View {
        switch status {
        case .idle:
            if userSettings.serverURL.isEmpty {
                Label("Not connected", systemImage: "circle.dashed")
                    .foregroundStyle(.secondary)
            } else {
                // Not verified yet on this screen; just show what is saved.
                LabeledContent("Saved server", value: userSettings.serverURL)
            }
        case .checking:
            Label("Checking connection…", systemImage: "ellipsis.circle")
                .foregroundStyle(.secondary)
        case .connected:
            Label("Connected to \(userSettings.serverURL)", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .failed(let message):
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
        }
    }

    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        return build.map { "\(version) (\($0))" } ?? version
    }

    /// Adds a scheme when missing and strips trailing slashes. Empty when the
    /// input is nothing but a scheme.
    private var normalizedURL: String {
        var cleaned = urlInput.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.isEmpty { return "" }
        if !cleaned.hasPrefix("http://") && !cleaned.hasPrefix("https://") {
            cleaned = "http://" + cleaned
        }
        while cleaned.hasSuffix("/") { cleaned.removeLast() }
        if cleaned == "http:" || cleaned == "https:" { return "" }
        return cleaned
    }

    private func connect() async {
        let url = normalizedURL
        guard !url.isEmpty else { return }

        status = .checking
        let probe = APIClient(baseURL: url)
        do {
            let health = try await probe.checkHealth()
            if health.isHealthy {
                userSettings.saveServerURL(url)
                status = .connected
                onConnected(url)
            } else {
                status = .failed("Server reported status “\(health.status)”.")
            }
        } catch {
            status = .failed("Unable to connect: \(error.localizedDescription)")
        }
    }
}
