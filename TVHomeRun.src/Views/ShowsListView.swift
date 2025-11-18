//
//  ShowsListView.swift
//  TVHomeRun
//
//  View displaying the list of available shows
//

import SwiftUI

struct ShowsListView: View {
    @ObservedObject var apiClient: APIClient
    @EnvironmentObject var userSettings: UserSettings
    @State private var shows: [Show] = []
    @State private var isLoading = true
    @State private var selectedShow: Show?
    @State private var showServerSettings = false

    var body: some View {
        ZStack {
            if isLoading {
                VStack(spacing: 30) {
                    ProgressView()
                        .scaleEffect(2)
                    Text("Loading shows...")
                        .font(.system(size: 32))
                }
            } else if shows.isEmpty {
                VStack(spacing: 30) {
                    Image(systemName: "tv.slash")
                        .font(.system(size: 100))
                        .foregroundColor(.gray)
                    Text("No shows available")
                        .font(.system(size: 36))
                        .foregroundColor(.gray)
                }
            } else {
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 400, maximum: 500), spacing: 40)
                    ], spacing: 40) {
                        ForEach(shows) { show in
                            ShowCardView(show: show)
                                .onTapGesture {
                                    selectedShow = show
                                }
                        }
                    }
                    .padding(60)
                }
            }
        }
        .navigationTitle("TV HomeRun")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showServerSettings = true
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 28))
                }
            }
        }
        .navigationDestination(item: $selectedShow) { show in
            EpisodesListView(apiClient: apiClient, show: show)
        }
        .sheet(isPresented: $showServerSettings) {
            ServerSetupView(userSettings: userSettings)
        }
        .alert("Connection Error", isPresented: $apiClient.showErrorAlert) {
            Button("OK") {
                apiClient.clearError()
            }
            Button("Retry") {
                loadShows()
            }
        } message: {
            if let error = apiClient.error {
                Text(error.localizedDescription)
            }
        }
        .task {
            await loadShows()
        }
    }

    private func loadShows() async {
        isLoading = true
        do {
            let fetchedShows = try await apiClient.fetchShows()
            await MainActor.run {
                shows = fetchedShows
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

struct ShowCardView: View {
    let show: Show

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Show image
            AsyncImage(url: URL(string: show.imageUrl ?? "")) { phase in
                switch phase {
                case .empty:
                    ZStack {
                        Color.gray.opacity(0.3)
                        ProgressView()
                    }
                    .frame(height: 300)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 300)
                        .clipped()
                case .failure:
                    ZStack {
                        Color.gray.opacity(0.3)
                        Image(systemName: "tv")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                    }
                    .frame(height: 300)
                @unknown default:
                    Color.gray.opacity(0.3)
                        .frame(height: 300)
                }
            }
            .cornerRadius(15)

            VStack(alignment: .leading, spacing: 8) {
                Text(show.title)
                    .font(.system(size: 28, weight: .semibold))
                    .lineLimit(2)

                HStack {
                    Text(show.category.capitalized)
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)

                    if show.episodeCount > 0 {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text("\(show.episodeCount) episode\(show.episodeCount == 1 ? "" : "s")")
                            .font(.system(size: 20))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 10)
        }
        .background(Color.gray.opacity(0.2))
        .cornerRadius(20)
        .shadow(radius: 10)
    }
}
