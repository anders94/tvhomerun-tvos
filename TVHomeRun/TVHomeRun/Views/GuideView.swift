//
//  GuideView.swift
//  TVHomeRun
//
//  View for browsing and searching upcoming TV programs
//

import SwiftUI

struct GuideView: View {
    @ObservedObject var apiClient: APIClient
    @State private var guideSeries: [GuideSeries] = []
    @State private var filteredSeries: [GuideSeries] = []
    @State private var isLoading = true
    @State private var searchText = ""
    @State private var recordedSeriesIds: Set<String> = []
    @State private var selectedSeries: GuideSeries?
    @State private var lastSelectedSeriesId: String?
    @FocusState private var focusedSeriesId: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            NavigationStack {
                ZStack {
                    if isLoading {
                        VStack(spacing: 30) {
                            ProgressView()
                                .scaleEffect(2)
                            Text("Loading guide...")
                                .font(.system(size: 32))
                        }
                    } else if filteredSeries.isEmpty {
                        VStack(spacing: 30) {
                            Image(systemName: searchText.isEmpty ? "tv" : "magnifyingglass")
                                .font(.system(size: 100))
                                .foregroundColor(.gray)
                            Text(searchText.isEmpty ? "No upcoming programs" : "No results found")
                                .font(.system(size: 36))
                                .foregroundColor(.gray)
                        }
                    } else {
                        ScrollView {
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 30),
                                GridItem(.flexible(), spacing: 30),
                                GridItem(.flexible(), spacing: 30),
                                GridItem(.flexible(), spacing: 30)
                            ], spacing: 30) {
                                ForEach(filteredSeries) { series in
                                    Button(action: {
                                        lastSelectedSeriesId = series.id
                                        selectedSeries = series
                                    }) {
                                        GuideSeriesCard(
                                            series: series,
                                            isRecording: recordedSeriesIds.contains(series.id)
                                        )
                                    }
                                    .buttonStyle(.card)
                                    .focused($focusedSeriesId, equals: series.id)
                                }
                            }
                            .padding(50)
                        }
                    }
                }
                .navigationTitle("Shows")
                .searchable(text: $searchText, prompt: "Search shows")
                .onChange(of: searchText) { _, newValue in
                    filterSeries(query: newValue)
                }
                .onChange(of: selectedSeries) { oldValue, newValue in
                    // When returning from detail view (newValue becomes nil)
                    if oldValue != nil && newValue == nil {
                        // Restore focus to the show we just came from
                        if let lastId = lastSelectedSeriesId {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                focusedSeriesId = lastId
                            }
                        }
                    }
                }
                .navigationDestination(item: $selectedSeries) { series in
                    GuideDetailView(
                        series: series,
                        apiClient: apiClient,
                        isRecording: recordedSeriesIds.contains(series.id)
                    )
                }
            }
        }
        .task {
            await loadGuide()
        }
    }

    private func loadGuide(forceRefresh: Bool = false) async {
        isLoading = true
        do {
            // Load guide and recording rules in parallel
            async let guideResponse = apiClient.fetchGuide(forceRefresh: forceRefresh)
            async let recordingRulesResponse = apiClient.fetchRecordingRules()

            let (guide, rules) = try await (guideResponse, recordingRulesResponse)

            await MainActor.run {
                // Store recorded series IDs
                recordedSeriesIds = Set(rules.rules.map { $0.seriesId })

                // Group programs by series
                var seriesDict: [String: GuideSeries] = [:]
                for channel in guide.channels {
                    for program in channel.guide {
                        // Create a new program instance with channel ID
                        var programWithChannel = program
                        programWithChannel.channelId = channel.guideNumber

                        if var existingSeries = seriesDict[program.seriesId] {
                            existingSeries = GuideSeries(
                                id: existingSeries.id,
                                title: existingSeries.title,
                                imageUrl: existingSeries.imageUrl,
                                programs: existingSeries.programs + [programWithChannel]
                            )
                            seriesDict[program.seriesId] = existingSeries
                        } else {
                            seriesDict[program.seriesId] = GuideSeries(
                                id: program.seriesId,
                                title: program.title,
                                imageUrl: program.imageUrl,
                                programs: [programWithChannel]
                            )
                        }
                    }
                }

                guideSeries = seriesDict.values.sorted { $0.title < $1.title }
                filteredSeries = guideSeries
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
            }
        }
    }

    private func filterSeries(query: String) {
        if query.isEmpty {
            filteredSeries = guideSeries
        } else {
            filteredSeries = guideSeries.filter {
                $0.title.localizedCaseInsensitiveContains(query)
            }
        }
    }
}

struct GuideSeriesCard: View {
    let series: GuideSeries
    let isRecording: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Series image with recording indicator
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: URL(string: series.imageUrl ?? "")) { phase in
                    switch phase {
                    case .empty:
                        ZStack {
                            Color.gray.opacity(0.3)
                            ProgressView()
                        }
                        .frame(height: 200)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 200)
                            .clipped()
                    case .failure:
                        ZStack {
                            Color.gray.opacity(0.3)
                            Image(systemName: "tv")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                        }
                        .frame(height: 200)
                    @unknown default:
                        Color.gray.opacity(0.3)
                            .frame(height: 200)
                    }
                }
                .cornerRadius(12)

                // Red recording indicator dot
                if isRecording {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 30, height: 30)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 3)
                        )
                        .padding(8)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(series.title)
                    .font(.system(size: 20, weight: .semibold))
                    .lineLimit(2)

                Text("\(series.upcomingCount) upcoming \(series.upcomingCount == 1 ? "episode" : "episodes")")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)

                if let firstProgram = series.programs.first {
                    Text("Next: \(firstProgram.formattedStartTime)")
                        .font(.system(size: 15))
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .background(Color.gray.opacity(0.2))
        .cornerRadius(15)
        .shadow(radius: 4)
    }
}
