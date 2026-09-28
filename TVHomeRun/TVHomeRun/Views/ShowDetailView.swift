//
//  ShowDetailView.swift
//  TVHomeRun
//
//  A recorded show: seasons on the left, episodes for the selected season on the right
//

import SwiftUI

struct ShowDetailView: View {
    @ObservedObject var apiClient: APIClient
    let show: Show

    /// Master list from the server. Refreshed in place so row identity is stable.
    @State private var episodes: [Episode] = []
    @State private var isLoading = true
    @State private var selectedSeason: SeasonKey?
    @State private var playingEpisode: Episode?
    @State private var pendingDelete: DeleteRequest?
    @State private var deleteFailure: String?
    @AppStorage(SortPreferenceKey.seasonOrder) private var seasonOrder: SeasonSortOrder = .descending
    @AppStorage(SortPreferenceKey.episodeOrder) private var episodeOrder: EpisodeDateOrder = .newestFirst
    @FocusState private var focus: Focus?

    nonisolated enum Focus: Hashable {
        case season(SeasonKey)
        case episode(Int)
    }

    struct DeleteRequest: Identifiable {
        let episode: Episode
        let allowRerecord: Bool
        var id: String { "\(episode.id)-\(allowRerecord)" }
    }

    // MARK: Derived state

    private var seasonGroups: [SeasonGroup]? {
        episodes.groupedBySeason(order: seasonOrder)
    }

    private var hasSeasons: Bool { seasonGroups != nil }

    /// The highest-numbered season, regardless of the sidebar sort order.
    private var defaultSeason: SeasonKey? {
        episodes.compactMap(\.seasonNumber).max().map(SeasonKey.season)
    }

    private var currentSeason: SeasonKey? {
        selectedSeason ?? defaultSeason
    }

    private var displayedEpisodes: [Episode] {
        guard let groups = seasonGroups else {
            return episodes.sortedByDate(episodeOrder)
        }
        let group = groups.first { $0.key == currentSeason }
        return (group?.episodes ?? []).sortedByDate(episodeOrder)
    }

    private var isPresentingDelete: Binding<Bool> {
        Binding(
            get: { pendingDelete != nil },
            set: { if !$0 { pendingDelete = nil } }
        )
    }

    private var isPresentingDeleteFailure: Binding<Bool> {
        Binding(
            get: { deleteFailure != nil },
            set: { if !$0 { deleteFailure = nil } }
        )
    }

    // MARK: Body

    var body: some View {
        Group {
            if isLoading && episodes.isEmpty {
                ProgressView("Loading episodes…")
            } else if episodes.isEmpty {
                ContentUnavailableView(
                    "No Episodes",
                    systemImage: "film.stack",
                    description: Text("There are no recordings of \(show.title).")
                )
            } else {
                content
            }
        }
        .navigationTitle(show.title)
        .fullScreenCover(item: $playingEpisode) { episode in
            // The displayed order drives "next episode" in the player.
            VideoPlayerView(episode: episode, allEpisodes: displayedEpisodes, apiClient: apiClient)
        }
        .onChange(of: playingEpisode) { oldValue, newValue in
            if oldValue != nil && newValue == nil {
                Task { await refreshEpisodesInPlace() }
            }
        }
        .onChange(of: focus) { oldValue, newValue in
            handleFocusChange(from: oldValue, to: newValue)
        }
        .alert("Delete Recording?", isPresented: isPresentingDelete, presenting: pendingDelete) { request in
            Button(request.allowRerecord ? "Delete and Allow Re-record" : "Delete", role: .destructive) {
                Task { await delete(request) }
            }
            Button("Cancel", role: .cancel) {}
        } message: { request in
            if request.allowRerecord {
                Text("“\(request.episode.displayTitle)” will be deleted. The DVR may record this episode again.")
            } else {
                Text("“\(request.episode.displayTitle)” will be permanently deleted.")
            }
        }
        .alert("Couldn't Delete Recording", isPresented: isPresentingDeleteFailure, presenting: deleteFailure) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
        }
        .task {
            await loadEpisodes()
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 30) {
            header

            HStack(alignment: .top, spacing: 40) {
                if let groups = seasonGroups {
                    SeasonSidebar(groups: groups, selected: currentSeason, focus: $focus) { key in
                        selectedSeason = key
                        if let first = displayedEpisodes.first {
                            focus = .episode(first.id)
                        }
                    }
                    .frame(width: 340)
                    .focusSection()
                }

                episodeList
                    .focusSection()
            }
        }
        .padding(.horizontal, 60)
        .padding(.top, 30)
        .defaultFocus($focus, displayedEpisodes.first.map { Focus.episode($0.id) })
    }

    // The page title comes from .navigationTitle, which tvOS renders above the content.
    private var header: some View {
        HStack(spacing: 30) {
            RecordSeriesToggle(seriesId: show.seriesId, apiClient: apiClient)
            EpisodeSortMenu(
                seasonOrder: $seasonOrder,
                episodeOrder: $episodeOrder,
                showsSeasonOrder: hasSeasons
            )
        }
    }

    private var episodeList: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                ForEach(displayedEpisodes) { episode in
                    Button {
                        playingEpisode = episode
                    } label: {
                        EpisodeRow(episode: episode)
                    }
                    .buttonStyle(.card)
                    .focused($focus, equals: .episode(episode.id))
                    .contextMenu {
                        contextMenuItems(for: episode)
                    }
                }
            }
            .padding(.vertical, 20)
            .padding(.bottom, 60)
        }
    }

    @ViewBuilder
    private func contextMenuItems(for episode: Episode) -> some View {
        Button(
            episode.isWatched ? "Mark as Unwatched" : "Mark as Watched",
            systemImage: episode.isWatched ? "eye.slash" : "checkmark.circle"
        ) {
            Task { await setWatched(!episode.isWatched, episode) }
        }
        Divider()
        Button("Delete", systemImage: "trash", role: .destructive) {
            pendingDelete = DeleteRequest(episode: episode, allowRerecord: false)
        }
        Button("Delete and Allow Re-record", systemImage: "arrow.clockwise.circle", role: .destructive) {
            pendingDelete = DeleteRequest(episode: episode, allowRerecord: true)
        }
    }

    // MARK: Focus

    /// Selection follows focus inside the sidebar. When focus enters the
    /// sidebar from the episode column it lands on whichever season row is
    /// geometrically nearest, so snap it back to the selected season instead
    /// of changing the list under the user.
    private func handleFocusChange(from oldValue: Focus?, to newValue: Focus?) {
        guard case .season(let key)? = newValue else { return }

        if case .season? = oldValue {
            selectedSeason = key
            return
        }

        if let current = currentSeason, key != current {
            focus = .season(current)
        } else {
            selectedSeason = key
        }
    }

    // MARK: Data

    private func loadEpisodes() async {
        isLoading = true
        defer { isLoading = false }
        if let response = try? await apiClient.fetchEpisodes(for: show.id) {
            episodes = response.episodes
        }
    }

    /// Re-fetches and patches rows by id so progress and watched state update
    /// without the list flickering. Falls back to a full replace when the
    /// episode count changed.
    private func refreshEpisodesInPlace() async {
        guard let response = try? await apiClient.fetchEpisodes(for: show.id) else { return }
        if response.episodes.count != episodes.count {
            episodes = response.episodes
            return
        }
        for updated in response.episodes {
            if let index = episodes.firstIndex(where: { $0.id == updated.id }) {
                episodes[index] = updated
            }
        }
    }

    private func setWatched(_ watched: Bool, _ episode: Episode) async {
        try? await apiClient.updateEpisodeProgress(
            episodeId: episode.id,
            position: watched ? episode.duration : 0,
            watched: watched
        )
        await refreshEpisodesInPlace()
    }

    private func delete(_ request: DeleteRequest) async {
        do {
            let response = try await apiClient.deleteEpisode(
                episodeId: request.episode.id,
                allowRerecord: request.allowRerecord
            )
            guard response.success else {
                deleteFailure = response.message
                return
            }
        } catch {
            // DELETE is never retried, so the shared connection alert
            // does not fire for it; report the failure here instead.
            deleteFailure = error.localizedDescription
            return
        }

        let removedIndex = displayedEpisodes.firstIndex { $0.id == request.episode.id }
        episodes.removeAll { $0.id == request.episode.id }

        // The selected season may have just lost its last episode.
        if let selected = selectedSeason,
           seasonGroups?.contains(where: { $0.key == selected }) != true {
            selectedSeason = nil
        }

        // Keep focus on the row that took the deleted row's place, else the previous one.
        let remaining = displayedEpisodes
        guard let removedIndex, !remaining.isEmpty else { return }
        focus = .episode(remaining[min(removedIndex, remaining.count - 1)].id)
    }
}
