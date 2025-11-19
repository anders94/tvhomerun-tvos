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
    @Namespace private var showsNamespace
    @State private var resetFocus = false
    @State private var lastSelectedShowId: Int?
    @FocusState private var focusedShowId: Int?

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
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 40),
                            GridItem(.flexible(), spacing: 40),
                            GridItem(.flexible(), spacing: 40)
                        ], spacing: 40) {
                            ForEach(shows) { show in
                                Button(action: {
                                    lastSelectedShowId = show.id
                                    selectedShow = show
                                }) {
                                    ShowCardView(show: show)
                                        .padding(8)
                                }
                                .buttonStyle(.card)
                                .id(show.id)
                                .focused($focusedShowId, equals: show.id)
                            }
                        }
                        .padding(60)
                    }
                    .id(resetFocus)
                    .onAppear {
                        // Restore focus when view appears
                        DispatchQueue.main.async {
                            if let lastId = lastSelectedShowId {
                                // Restore to last selected show
                                proxy.scrollTo(lastId, anchor: .center)
                                focusedShowId = lastId
                            } else if let firstShow = shows.first {
                                // Focus first show if no saved position
                                focusedShowId = firstShow.id
                            }
                        }
                    }
                    .onChange(of: selectedShow) { oldValue, newValue in
                        // When returning from episodes (newValue becomes nil)
                        if oldValue != nil && newValue == nil {
                            DispatchQueue.main.async {
                                if let lastId = lastSelectedShowId {
                                    proxy.scrollTo(lastId, anchor: .center)
                                    focusedShowId = lastId
                                } else if let firstShow = shows.first {
                                    focusedShowId = firstShow.id
                                }
                            }
                        }
                    }
                }
            }
        }
        .focusScope(showsNamespace)
        .navigationTitle("TV HomeRun")
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
            ServerSetupView(userSettings: userSettings, onSettingsSaved: {
                showServerSettings = false
            })
        }
        .alert("Connection Error", isPresented: $apiClient.showErrorAlert) {
            Button("OK") {
                apiClient.clearError()
            }
            Button("Retry") {
                Task {
                    await loadShows()
                }
            }
        } message: {
            if let error = apiClient.error {
                Text(error.localizedDescription)
            }
        }
        .task {
            await loadShows()
        }
        .onChange(of: isLoading) { oldValue, newValue in
            if !newValue && !shows.isEmpty {
                // Set initial focus to first show when shows finish loading
                DispatchQueue.main.async {
                    if lastSelectedShowId == nil, let firstShow = shows.first {
                        focusedShowId = firstShow.id
                    }
                }
            }
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
                    .frame(height: 260)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 260)
                        .clipped()
                case .failure:
                    ZStack {
                        Color.gray.opacity(0.3)
                        Image(systemName: "tv")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                    }
                    .frame(height: 260)
                @unknown default:
                    Color.gray.opacity(0.3)
                        .frame(height: 260)
                }
            }
            .cornerRadius(15)

            VStack(alignment: .leading, spacing: 8) {
                Text(show.title)
                    .font(.system(size: 24, weight: .semibold))
                    .lineLimit(2)

                HStack {
                    Text(show.category.capitalized)
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)

                    if show.episodeCount > 0 {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text("\(show.episodeCount) episode\(show.episodeCount == 1 ? "" : "s")")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 10)
        }
        .background(Color.gray.opacity(0.2))
        .cornerRadius(20)
        .shadow(radius: 5)
    }
}
