//
//  LiveChannelsView.swift
//  TVHomeRun
//
//  Live TV tab: channel lineup with what's on now
//

import SwiftUI

struct LiveChannelsView: View {
    @ObservedObject var apiClient: APIClient
    @State private var channels: [Channel] = []
    @State private var currentPrograms: [String: CurrentProgram] = [:]
    @State private var isLoading = true
    @State private var selectedChannel: Channel?

    var body: some View {
        Group {
            if isLoading && channels.isEmpty {
                ProgressView("Loading channels…")
            } else if channels.isEmpty {
                ContentUnavailableView(
                    "No Channels",
                    systemImage: "tv",
                    description: Text("No live channels were found on your HDHomeRun.")
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 24) {
                        ForEach(channels) { channel in
                            Button {
                                selectedChannel = channel
                            } label: {
                                ChannelRow(
                                    channel: channel,
                                    currentProgram: currentPrograms[channel.guideNumber]
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
        .navigationTitle("Live TV")
        .fullScreenCover(item: $selectedChannel) { channel in
            LiveVideoPlayerView(channel: channel, apiClient: apiClient)
        }
        .task(id: apiClient.baseURL) {
            await loadChannels()
        }
    }

    private func loadChannels() async {
        isLoading = true
        defer { isLoading = false }
        do {
            async let channelsResponse = apiClient.fetchLiveChannels()
            async let programsResponse = apiClient.fetchCurrentPrograms()
            let (lineup, programs) = try await (channelsResponse, programsResponse)

            channels = lineup.channels.sorted(by: Channel.guideNumberAscending)
            currentPrograms = Dictionary(
                programs.programs.map { ($0.guideNumber, $0) },
                uniquingKeysWith: { first, _ in first }
            )
        } catch {
            // The shared connection alert reports the failure.
        }
    }
}

struct ChannelRow: View {
    let channel: Channel
    let currentProgram: CurrentProgram?

    var body: some View {
        HStack(spacing: 30) {
            RemoteImage(url: channel.imageUrl, contentMode: .fit)
                .frame(width: 120, height: 120)
                .padding(12)
                .background(.black.opacity(0.85), in: .rect(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Text(channel.guideNumber)
                        .font(.headline)
                        .monospacedDigit()
                    Text(channel.guideName)
                        .font(.headline)
                    if let affiliate = channel.affiliate, !affiliate.isEmpty {
                        Text(affiliate)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if let program = currentProgram {
                    Text(program.title)
                        .font(.callout)
                        .foregroundStyle(.tint)
                        .lineLimit(1)
                    if let episodeTitle = program.episodeTitle, !episodeTitle.isEmpty {
                        Text(episodeTitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Text(program.formattedTime)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("No program information")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }
}
