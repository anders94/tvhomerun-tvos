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
    @FocusState private var focusedShowID: Show.ID?
    /// Last highlighted show, restored on launch so the user lands where they left off.
    @AppStorage("lastFocusedShowID") private var lastFocusedShowID: Int?
    @State private var hasRestoredFocus = false

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
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 40) {
                            ForEach(shows) { show in
                                NavigationLink(value: show) {
                                    ShowCardView(show: show)
                                }
                                .buttonStyle(.card)
                                .focused($focusedShowID, equals: show.id)
                                .id(show.id)
                            }
                        }
                        .padding(.horizontal, 80)
                        .padding(.vertical, 40)
                    }
                    // Treat the grid as one focus region so moving down from the
                    // tab bar lands on the first show, not whichever card is
                    // geometrically closest to the selected tab.
                    .focusSection()
                    .defaultFocus($focusedShowID, shows.first?.id, priority: .userInitiated)
                    .task(id: shows.map(\.id)) {
                        await restoreFocus(using: proxy)
                    }
                }
            }
        }
        .onChange(of: focusedShowID) { _, newValue in
            if let newValue { lastFocusedShowID = newValue }
        }
        .navigationTitle("Recordings")
        .navigationDestination(for: Show.self) { show in
            ShowDetailView(apiClient: apiClient, show: show)
        }
        .task(id: apiClient.baseURL) {
            await loadShows()
        }
    }

    /// On launch, move focus from the tab bar into the grid: the last
    /// highlighted show if it still exists, otherwise the first one.
    private func restoreFocus(using proxy: ScrollViewProxy) async {
        guard !hasRestoredFocus, let first = shows.first else { return }
        hasRestoredFocus = true
        let target = shows.first(where: { $0.id == lastFocusedShowID })?.id ?? first.id
        proxy.scrollTo(target, anchor: .center)
        // Let the lazy grid materialize the card before focusing it.
        await Task.yield()
        focusedShowID = target
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
                    // Always reserve two lines so every card is the same height.
                    .lineLimit(2, reservesSpace: true)
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
