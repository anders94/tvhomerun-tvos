//
//  LiveChannelsView.swift
//  TVHomeRun
//
//  View for displaying live TV channels and current programs
//

import SwiftUI

struct LiveChannelsView: View {
    @Environment(\.dismiss) var dismiss
    let apiClient: APIClient
    @State private var channels: [Channel] = []
    @State private var currentPrograms: [String: CurrentProgram] = [:]
    @State private var isLoading = true
    @State private var selectedChannel: Channel?
    @FocusState private var focusedChannelId: String?

    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()

            if isLoading {
                VStack(spacing: 30) {
                    ProgressView()
                        .scaleEffect(2)
                    Text("Loading channels...")
                        .font(.system(size: 32))
                }
            } else if channels.isEmpty {
                VStack(spacing: 30) {
                    Image(systemName: "tv")
                        .font(.system(size: 100))
                        .foregroundColor(.gray)
                    Text("No channels available")
                        .font(.system(size: 36))
                        .foregroundColor(.gray)
                }
            } else {
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 28))
                                Text("Back")
                                    .font(.system(size: 28))
                            }
                            .foregroundColor(.white)
                        }

                        Spacer()

                        Text("Live TV")
                            .font(.system(size: 56, weight: .bold))

                        Spacer()

                        // Placeholder for symmetry
                        HStack(spacing: 12) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 28))
                            Text("Back")
                                .font(.system(size: 28))
                        }
                        .foregroundColor(.white)
                        .opacity(0)
                    }
                    .padding(.horizontal, 50)
                    .padding(.vertical, 30)
                    .background(.ultraThinMaterial)

                    // Channel list
                    ScrollView {
                        LazyVStack(spacing: 20) {
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
                                .focused($focusedChannelId, equals: channel.id)
                            }
                        }
                        .padding(50)
                    }
                }
            }
        }
        .task {
            await loadChannels()
        }
        .fullScreenCover(item: $selectedChannel) { channel in
            LiveVideoPlayerView(
                channel: channel,
                apiClient: apiClient
            )
        }
        .onAppear {
            // Set initial focus
            if let firstChannel = channels.first {
                focusedChannelId = firstChannel.id
            }
        }
    }

    private func loadChannels() async {
        isLoading = true
        do {
            // Load channels and current programs in parallel
            async let channelsResponse = apiClient.fetchLiveChannels()
            async let programsResponse = apiClient.fetchCurrentPrograms()

            let (channels, programs) = try await (channelsResponse, programsResponse)

            await MainActor.run {
                self.channels = channels.channels.sorted { $0.guideNumber < $1.guideNumber }

                // Build dictionary for quick lookup
                var programsDict: [String: CurrentProgram] = [:]
                for program in programs.programs {
                    programsDict[program.guideNumber] = program
                }
                self.currentPrograms = programsDict

                isLoading = false

                // Set initial focus after data loads
                if let firstChannel = self.channels.first {
                    focusedChannelId = firstChannel.id
                }
            }
        } catch {
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

struct ChannelRow: View {
    let channel: Channel
    let currentProgram: CurrentProgram?

    var body: some View {
        HStack(spacing: 20) {
            // Channel logo with tile background
            ZStack {
                // Background tile
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.85))

                AsyncImage(url: URL(string: channel.imageUrl ?? "")) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding(12)
                    case .failure:
                        Image(systemName: "tv")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                    @unknown default:
                        Image(systemName: "tv")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                    }
                }
            }
            .frame(width: 120, height: 120)

            VStack(alignment: .leading, spacing: 10) {
                // Channel info
                HStack(spacing: 12) {
                    Text(channel.guideNumber)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)

                    Text(channel.guideName)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.primary)

                    if let affiliate = channel.affiliate {
                        Text(affiliate)
                            .font(.system(size: 20))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(6)
                    }
                }

                // Current program
                if let program = currentProgram {
                    Text(program.title)
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                        .lineLimit(1)

                    if let episodeTitle = program.episodeTitle {
                        Text(episodeTitle)
                            .font(.system(size: 20))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                    Text(program.formattedTime)
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                } else {
                    Text("No program information")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 24))
                .foregroundColor(.gray)
        }
        .padding(20)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(15)
    }
}
