//
//  EpisodesListView.swift
//  TVHomeRun
//
//  View displaying the list of episodes for a show
//

import SwiftUI

struct EpisodesListView: View {
    @ObservedObject var apiClient: APIClient
    let show: Show
    @State private var episodes: [Episode] = []
    @State private var isLoading = true
    @State private var selectedEpisode: Episode?

    var body: some View {
        ZStack {
            if isLoading {
                VStack(spacing: 30) {
                    ProgressView()
                        .scaleEffect(2)
                    Text("Loading episodes...")
                        .font(.system(size: 32))
                }
            } else if episodes.isEmpty {
                VStack(spacing: 30) {
                    Image(systemName: "film.stack")
                        .font(.system(size: 100))
                        .foregroundColor(.gray)
                    Text("No episodes available")
                        .font(.system(size: 36))
                        .foregroundColor(.gray)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(episodes) { episode in
                            Button(action: {
                                selectedEpisode = episode
                            }) {
                                EpisodeRowView(episode: episode)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(60)
                }
            }
        }
        .navigationTitle(show.title)
        .fullScreenCover(item: $selectedEpisode) { episode in
            VideoPlayerView(episode: episode, allEpisodes: episodes, apiClient: apiClient)
        }
        .alert("Connection Error", isPresented: $apiClient.showErrorAlert) {
            Button("OK") {
                apiClient.clearError()
            }
            Button("Retry") {
                Task {
                    await loadEpisodes()
                }
            }
        } message: {
            if let error = apiClient.error {
                Text(error.localizedDescription)
            }
        }
        .task {
            await loadEpisodes()
        }
        .onChange(of: selectedEpisode) { oldValue, newValue in
            // When returning from video player (newValue becomes nil)
            if oldValue != nil && newValue == nil {
                Task {
                    await loadEpisodes()
                }
            }
        }
    }

    private func loadEpisodes() async {
        isLoading = true
        do {
            let response = try await apiClient.fetchEpisodes(for: show.id)
            await MainActor.run {
                // Episodes are already in newest-first order from the API
                episodes = response.episodes
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

struct EpisodeRowView: View {
    let episode: Episode

    var body: some View {
        HStack(spacing: 30) {
            // Episode thumbnail
            AsyncImage(url: URL(string: episode.imageUrl ?? "")) { phase in
                switch phase {
                case .empty:
                    ZStack {
                        Color.gray.opacity(0.3)
                        ProgressView()
                    }
                    .frame(width: 300, height: 200)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 300, height: 200)
                        .clipped()
                case .failure:
                    ZStack {
                        Color.gray.opacity(0.3)
                        Image(systemName: "play.rectangle")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                    }
                    .frame(width: 300, height: 200)
                @unknown default:
                    Color.gray.opacity(0.3)
                        .frame(width: 300, height: 200)
                }
            }
            .cornerRadius(12)
            .overlay(
                ZStack {
                    // Progress indicator overlay
                    if episode.progressPercentage > 0 {
                        VStack {
                            Spacer()
                            GeometryReader { geometry in
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(Color.red)
                                    .frame(width: geometry.size.width * episode.progressPercentage,
                                           height: 10)
                            }
                            .frame(height: 8)
                        }
                    }

                    // Watched indicator
                    if episode.isWatched {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.green)
                                    .padding(10)
                            }
                            Spacer()
                        }
                    }

                    // Resume indicator
                    if let resumePos = episode.resumePosition, resumePos > 0, !episode.isWatched {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                            .shadow(radius: 5)
                    }
                }
            )

            // Episode info
            VStack(alignment: .leading, spacing: 12) {
                // Episode number and title
                Text(episode.episodeNumber)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.blue)

                Text(episode.episodeTitle)
                    .font(.system(size: 32, weight: .bold))
                    .lineLimit(2)

                // Synopsis
                Text(episode.synopsis)
                    .font(.system(size: 24))
                    .foregroundColor(.secondary)
                    .lineLimit(3)

                Spacer()

                // Metadata
                HStack(spacing: 20) {
                    Label(episode.formattedAirDate, systemImage: "calendar")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)

                    Label(episode.formattedDuration, systemImage: "clock")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)

                    Label(episode.channelNumber, systemImage: "tv")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)

                    if let resumePos = episode.resumePosition, resumePos > 0 {
                        Label("\(episode.resumeMinutes)m watched", systemImage: "eye")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(.vertical, 15)

            Spacer()
        }
        .padding(20)
        .background(Color.gray.opacity(0.15))
        .cornerRadius(15)
        .shadow(radius: 5)
    }
}
