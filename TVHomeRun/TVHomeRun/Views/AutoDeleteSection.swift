//
//  AutoDeleteSection.swift
//  TVHomeRun
//
//  Settings section for the backend's auto-delete of watched episodes
//

import SwiftUI

struct AutoDeleteSection: View {
    @ObservedObject var apiClient: APIClient

    @State private var state: LoadState = .loading
    @State private var settings = ServerSettings(autoDeleteWatched: false, autoDeleteAfterDays: 30)
    @State private var saveError: String?

    private static let presetDays = [7, 14, 30, 60, 90]

    private enum LoadState: Equatable {
        case loading
        case loaded
        case unsupported
        case failed(String)
    }

    var body: some View {
        Section {
            switch state {
            case .loading:
                Label {
                    Text("Loading…")
                } icon: {
                    ProgressView()
                }
                .foregroundStyle(.secondary)
            case .unsupported:
                Label("This server doesn't support automatic deletion yet.", systemImage: "info.circle")
                    .foregroundStyle(.secondary)
            case .failed(let message):
                Button {
                    Task { await load() }
                } label: {
                    Label("Couldn't load settings: \(message) Select to retry.", systemImage: "exclamationmark.triangle.fill")
                }
            case .loaded:
                Toggle("Delete Watched Episodes", isOn: binding(\.autoDeleteWatched))

                if settings.autoDeleteWatched {
                    Picker("Delete After", selection: binding(\.autoDeleteAfterDays)) {
                        ForEach(dayOptions, id: \.self) { days in
                            Text("\(days) days").tag(days)
                        }
                    }
                }

                if let saveError {
                    Label(saveError, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                }
            }
        } header: {
            Text("Storage")
        } footer: {
            Text("Episodes you've watched (90% or more, or into the last 3 minutes) are deleted from the DVR once they haven't been played for this long. This applies to every device using this server.")
        }
        .task(id: apiClient.baseURL) {
            await load()
        }
    }

    /// Include the saved value in the picker even if it isn't a preset.
    private var dayOptions: [Int] {
        Set(Self.presetDays + [settings.autoDeleteAfterDays]).sorted()
    }

    /// Updates one field and saves it, reverting if the server rejects it.
    private func binding<Value>(_ keyPath: WritableKeyPath<ServerSettings, Value>) -> Binding<Value> {
        Binding {
            settings[keyPath: keyPath]
        } set: { newValue in
            let previous = settings
            settings[keyPath: keyPath] = newValue
            Task { await save(reverting: previous) }
        }
    }

    private func load() async {
        state = .loading
        saveError = nil
        do {
            settings = try await apiClient.fetchSettings()
            state = .loaded
        } catch APIError.serverError(404), APIError.serverRejected(404, _) {
            state = .unsupported
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    private func save(reverting previous: ServerSettings) async {
        saveError = nil
        do {
            settings = try await apiClient.updateSettings(settings)
        } catch {
            settings = previous
            saveError = "Couldn't save: \(error.localizedDescription)"
        }
    }
}
