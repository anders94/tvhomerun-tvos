//
//  PreviewData.swift
//  TVHomeRun
//
//  Sample models and Xcode previews for the reusable views
//

#if DEBUG
import SwiftUI

extension Show {
    static let preview = Show(
        id: 1,
        seriesId: "C1234567890",
        title: "Nature Documentaries",
        category: "series",
        imageUrl: nil,
        episodeCount: 12,
        totalDuration: 43_200,
        firstRecorded: nil,
        lastRecorded: nil,
        createdAt: "",
        updatedAt: "",
        deviceName: "HDHomeRun",
        deviceIp: "192.168.1.50",
        durationHours: 12
    )
}

extension Episode {
    static func preview(
        id: Int,
        season: Int? = 3,
        episode: Int? = 4,
        title: String = "The Deep Ocean",
        recordedDaysAgo: Int = 2,
        resumePosition: Int? = nil,
        watched: Bool = false
    ) -> Episode {
        let recorded = Int(Date().timeIntervalSince1970) - recordedDaysAgo * 86_400
        let code: String
        if let season, let episode {
            code = String(format: "S%02dE%02d", season, episode)
        } else {
            code = ""
        }
        return Episode(
            id: id,
            programId: "EP\(id)",
            title: "Nature Documentaries",
            episodeTitle: title,
            episodeNumber: code,
            seasonNumber: season,
            episodeNum: episode,
            synopsis: "Cameras descend to the ocean floor to film creatures that have never been seen alive.",
            category: "series",
            channelName: "PBS",
            channelNumber: "11.1",
            channelImageUrl: nil,
            startTime: "",
            endTime: "",
            duration: 3_600,
            originalAirdate: ISO8601DateFormatter().string(from: Date(timeIntervalSince1970: TimeInterval(recorded))),
            recordStartTime: recorded,
            recordEndTime: recorded + 3_600,
            firstAiring: 1,
            filename: "",
            fileSize: nil,
            playUrl: "",
            cmdUrl: "",
            resumePosition: resumePosition,
            watched: watched ? 1 : 0,
            recordSuccess: 1,
            imageUrl: nil,
            createdAt: "",
            updatedAt: "",
            seriesId: "C1234567890",
            seriesTitle: "Nature Documentaries",
            durationMinutes: 60,
            resumeMinutes: (resumePosition ?? 0) / 60,
            hlsCacheBytes: 850_000_000
        )
    }

    static let previewList: [Episode] = [
        .preview(id: 1, season: 3, episode: 4, recordedDaysAgo: 1, resumePosition: 1_200),
        .preview(id: 2, season: 3, episode: 3, title: "Frozen Worlds", recordedDaysAgo: 8, watched: true),
        .preview(id: 3, season: 2, episode: 9, title: "Jungles", recordedDaysAgo: 40),
        .preview(id: 4, season: nil, episode: nil, title: "Behind the Lens", recordedDaysAgo: 3)
    ]
}

extension Channel {
    static let preview = Channel(guideNumber: "11.1", guideName: "WPBS", affiliate: "PBS", imageUrl: nil)
}

extension CurrentProgram {
    static let preview = CurrentProgram(
        guideNumber: "11.1",
        guideName: "WPBS",
        affiliate: "PBS",
        seriesId: "C1234567890",
        title: "Nature Documentaries",
        episodeNumber: "S03E04",
        episodeTitle: "The Deep Ocean",
        startTime: Int(Date().timeIntervalSince1970) - 900,
        endTime: Int(Date().timeIntervalSince1970) + 2_700,
        imageUrl: nil
    )
}

#Preview("Show card") {
    ShowCardView(show: .preview)
        .frame(width: 400)
        .padding()
}

#Preview("Episode row") {
    VStack(spacing: 24) {
        ForEach(Episode.previewList) { EpisodeRow(episode: $0) }
    }
    .padding(60)
}

#Preview("Channel row") {
    ChannelRow(channel: .preview, currentProgram: .preview)
        .padding(60)
}

#Preview("Season sidebar") {
    @Previewable @FocusState var focus: ShowDetailView.Focus?
    SeasonSidebar(
        groups: Episode.previewList.groupedBySeason(order: .descending) ?? [],
        selected: .season(3),
        focus: $focus
    ) { _ in }
    .frame(width: 340)
    .padding(60)
}

#Preview("Sort menu") {
    @Previewable @State var seasonOrder: SeasonSortOrder = .descending
    @Previewable @State var episodeOrder: EpisodeDateOrder = .newestFirst
    EpisodeSortMenu(seasonOrder: $seasonOrder, episodeOrder: $episodeOrder, showsSeasonOrder: true)
        .padding(60)
}

#Preview("Server form") {
    ServerConnectionForm(showsAppInfo: true) { _ in }
        .environmentObject(UserSettings())
}
#endif
