//
//  GuideView.swift
//  TVHomeRun
//
//  Guide tab: browse and search upcoming programs, grouped by series
//

import SwiftUI

struct GuideView: View {
    @ObservedObject var apiClient: APIClient
    @State private var guideSeries: [GuideSeries] = []
    @State private var isLoading = true
    @State private var searchText = ""
    @State private var recordedSeriesIds: Set<String> = []

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 40), count: 4)

    private var filteredSeries: [GuideSeries] {
        guard !searchText.isEmpty else { return guideSeries }
        return guideSeries.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        Group {
            if isLoading && guideSeries.isEmpty {
                ProgressView("Loading guide…")
            } else if filteredSeries.isEmpty {
                if searchText.isEmpty {
                    ContentUnavailableView(
                        "No Upcoming Programs",
                        systemImage: "calendar",
                        description: Text("Guide data will appear here once your HDHomeRun has downloaded it.")
                    )
                } else {
                    ContentUnavailableView.search(text: searchText)
                }
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 40) {
                        ForEach(filteredSeries) { series in
                            NavigationLink(value: series) {
                                GuideSeriesCard(
                                    series: series,
                                    isRecording: recordedSeriesIds.contains(series.id)
                                )
                            }
                            .buttonStyle(.card)
                        }
                    }
                    .padding(.horizontal, 80)
                    .padding(.vertical, 40)
                }
            }
        }
        .navigationTitle("Guide")
        .searchable(text: $searchText, prompt: "Search shows")
        .navigationDestination(for: GuideSeries.self) { series in
            GuideDetailView(
                series: series,
                apiClient: apiClient,
                isRecording: recordedSeriesIds.contains(series.id)
            )
        }
        .task(id: apiClient.baseURL) {
            await loadGuide()
        }
    }

    private func loadGuide() async {
        isLoading = true
        defer { isLoading = false }
        do {
            async let guideResponse = apiClient.fetchGuide()
            async let rulesResponse = apiClient.fetchRecordingRules()
            let (guide, rules) = try await (guideResponse, rulesResponse)
            recordedSeriesIds = Set(rules.rules.map(\.seriesId))
            guideSeries = Self.groupBySeries(guide.channels)
        } catch {
            // The shared connection alert reports the failure.
        }
    }

    /// Flattens the per-channel guide into one entry per series, with each
    /// series' airings in chronological order and series sorted by title.
    private static func groupBySeries(_ channels: [GuideChannel]) -> [GuideSeries] {
        var programsBySeries: [String: [GuideProgram]] = [:]
        var info: [String: (title: String, imageUrl: String?)] = [:]

        for channel in channels {
            for program in channel.guide {
                var stamped = program
                stamped.channelId = channel.guideNumber
                programsBySeries[program.seriesId, default: []].append(stamped)
                if info[program.seriesId] == nil {
                    info[program.seriesId] = (program.title, program.imageUrl)
                }
            }
        }

        return programsBySeries.map { seriesId, programs in
            GuideSeries(
                id: seriesId,
                title: info[seriesId]?.title ?? "",
                imageUrl: info[seriesId]?.imageUrl,
                programs: programs.sorted { a, b in
                    if a.startTime != b.startTime { return a.startTime < b.startTime }
                    return Channel.compareGuideNumbers(a.channelId ?? "", b.channelId ?? "")
                }
            )
        }
        .sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
    }
}

struct GuideSeriesCard: View {
    let series: GuideSeries
    let isRecording: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RemoteImage(url: series.imageUrl)
                .frame(height: 220)
                .overlay(alignment: .topTrailing) {
                    if isRecording {
                        Image(systemName: "record.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.white, .red)
                            .padding(10)
                    }
                }
                .clipShape(.rect(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(series.title)
                    .font(.headline)
                    .lineLimit(2)
                Text("\(series.upcomingCount) upcoming \(series.upcomingCount == 1 ? "airing" : "airings")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let next = series.programs.first {
                    Text("Next: \(next.formattedStartTime)")
                        .font(.caption)
                        .foregroundStyle(.tint)
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }
}
