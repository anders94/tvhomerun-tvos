//
//  EpisodeRow.swift
//  TVHomeRun
//
//  One recorded episode in the show detail list
//

import SwiftUI

struct EpisodeRow: View {
    let episode: Episode

    var body: some View {
        HStack(alignment: .top, spacing: 30) {
            thumbnail

            VStack(alignment: .leading, spacing: 10) {
                if !episode.episodeNumber.isEmpty {
                    Text(episode.episodeNumber)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.tint)
                }

                Text(episode.displayTitle)
                    .font(.headline)
                    .lineLimit(2)

                if !episode.synopsis.isEmpty {
                    Text(episode.synopsis)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }

                metadata
                    .padding(.top, 4)
            }

            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }

    private var thumbnail: some View {
        RemoteImage(url: episode.imageUrl, fallbackSystemImage: "play.rectangle")
            .frame(width: 300, height: 170)
            .overlay(alignment: .bottom) {
                if episode.progressPercentage > 0 {
                    ProgressView(value: episode.progressPercentage)
                        .tint(.red)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 8)
                }
            }
            .overlay(alignment: .topTrailing) {
                if episode.isWatched {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.white, .green)
                        .padding(10)
                }
            }
            .clipShape(.rect(cornerRadius: 12, style: .continuous))
    }

    private var metadata: some View {
        HStack(spacing: 24) {
            Label(episode.formattedAirDate, systemImage: "calendar")
            Label(episode.formattedDuration, systemImage: "clock")
            Label(episode.channelNumber, systemImage: "tv")
            Label(episode.formattedCacheSize, systemImage: "internaldrive")
            if let resume = episode.resumePosition, resume > 0, !episode.isWatched {
                Label("\(episode.resumeMinutes)m watched", systemImage: "play.circle")
                    .foregroundStyle(.tint)
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .lineLimit(1)
    }
}
