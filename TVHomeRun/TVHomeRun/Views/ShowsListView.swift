//
//  ShowsListView.swift
//  TVHomeRun
//
//  Recordings tab: grid of recorded shows
//

import SwiftUI

struct ShowsListView: View {
    @ObservedObject var apiClient: APIClient
    @State private var shows: [Show] = []
    @State private var isLoading = true

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 40), count: 4)

    var body: some View {
        Group {
            if isLoading && shows.isEmpty {
                ProgressView("Loading shows…")
            } else if shows.isEmpty {
                ContentUnavailableView(
                    "No Recordings",
                    systemImage: "tv.slash",
                    description: Text("Recorded shows will appear here once your HDHomeRun has recorded something.")
                )
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 40) {
                        ForEach(shows) { show in
                            NavigationLink(value: show) {
                                ShowCardView(show: show)
                            }
                            .buttonStyle(.card)
                        }
                    }
                    .padding(.horizontal, 80)
                    .padding(.vertical, 40)
                }
            }
        }
        .navigationTitle("Recordings")
        .navigationDestination(for: Show.self) { show in
            ShowDetailView(apiClient: apiClient, show: show)
        }
        .task(id: apiClient.baseURL) {
            await loadShows()
        }
    }

    private func loadShows() async {
        isLoading = true
        defer { isLoading = false }
        if let fetched = try? await apiClient.fetchShows() {
            shows = fetched
        }
    }
}

struct ShowCardView: View {
    let show: Show

    private var subtitle: String {
        var parts = [show.category.capitalized]
        if show.episodeCount > 0 {
            parts.append("\(show.episodeCount) episode\(show.episodeCount == 1 ? "" : "s")")
        }
        return parts.filter { !$0.isEmpty }.joined(separator: " · ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RemoteImage(url: show.imageUrl)
                .frame(height: 220)
                .clipShape(.rect(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(show.title)
                    .font(.headline)
                    .lineLimit(2)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }
}
