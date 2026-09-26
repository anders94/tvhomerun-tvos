//
//  GuideDetailView.swift
//  TVHomeRun
//
//  Upcoming airings for a series from the guide, with a series recording toggle
//

import SwiftUI

struct GuideDetailView: View {
    let series: GuideSeries
    @ObservedObject var apiClient: APIClient
    let isRecording: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                HStack(spacing: 30) {
                    Text(series.title)
                        .font(.title)
                        .lineLimit(1)
                    Spacer()
                    RecordSeriesToggle(
                        seriesId: series.id,
                        apiClient: apiClient,
                        assumeRecording: isRecording
                    )
                }

                Text("Upcoming Airings")
                    .font(.title3)

                if series.programs.isEmpty {
                    Text("No upcoming airings found.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                } else {
                    LazyVStack(spacing: 24) {
                        ForEach(series.programs) { program in
                            // Focusable so the list can be scrolled with the remote.
                            Button {} label: {
                                GuideProgramCard(program: program)
                            }
                            .buttonStyle(.card)
                        }
                    }
                }
            }
            .padding(.horizontal, 60)
            .padding(.vertical, 30)
        }
        .navigationTitle(series.title)
    }
}

struct GuideProgramCard: View {
    let program: GuideProgram

    var body: some View {
        HStack(alignment: .top, spacing: 30) {
            RemoteImage(url: program.imageUrl)
                .frame(width: 130, height: 190)
                .clipShape(.rect(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 10) {
                if let episodeTitle = program.episodeTitle, !episodeTitle.isEmpty {
                    Text(episodeTitle)
                        .font(.headline)
                        .lineLimit(2)
                } else {
                    Text(program.title)
                        .font(.headline)
                        .lineLimit(2)
                }

                if let episodeNumber = program.episodeNumber, !episodeNumber.isEmpty {
                    Text(episodeNumber)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.tint)
                }

                HStack(spacing: 24) {
                    Label(program.formattedStartTime, systemImage: "calendar")
                    Label("\(program.durationMinutes) min", systemImage: "clock")
                    if let channel = program.channelId {
                        Label(channel, systemImage: "tv")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                if let synopsis = program.synopsis, !synopsis.isEmpty {
                    Text(synopsis)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }
}
