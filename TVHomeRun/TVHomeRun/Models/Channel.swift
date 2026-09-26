//
//  Channel.swift
//  TVHomeRun
//
//  Data models for Live TV channels and streaming
//

import Foundation

// Response from /api/live/channels
struct ChannelsResponse: Codable {
    let channels: [Channel]
    let count: Int
    let timestamp: String
}

struct Channel: Codable, Identifiable {
    let guideNumber: String
    let guideName: String
    let affiliate: String?
    let imageUrl: String?

    var id: String { guideNumber }

    enum CodingKeys: String, CodingKey {
        case guideNumber = "guide_number"
        case guideName = "guide_name"
        case affiliate
        case imageUrl = "image_url"
    }
}

// Response from /api/guide/now
struct CurrentProgramsResponse: Codable {
    let programs: [CurrentProgram]
    let count: Int
    let timestamp: String
}

struct CurrentProgram: Codable {
    let guideNumber: String
    let guideName: String
    let affiliate: String?
    let seriesId: String
    let title: String
    let episodeNumber: String?
    let episodeTitle: String?
    let startTime: Int
    let endTime: Int
    let imageUrl: String?

    enum CodingKeys: String, CodingKey {
        case guideNumber = "guide_number"
        case guideName = "guide_name"
        case affiliate
        case seriesId = "series_id"
        case title
        case episodeNumber = "episode_number"
        case episodeTitle = "episode_title"
        case startTime = "start_time"
        case endTime = "end_time"
        case imageUrl = "image_url"
    }

    var formattedTime: String {
        let start = Date(timeIntervalSince1970: TimeInterval(startTime))
        let end = Date(timeIntervalSince1970: TimeInterval(endTime))
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        let ampm = DateFormatter()
        ampm.dateFormat = "a"
        return "\(formatter.string(from: start))-\(formatter.string(from: end)) \(ampm.string(from: end))"
    }
}

// Response from /api/live/watch
struct WatchResponse: Codable {
    let success: Bool
    let tunerId: String
    let playlistUrl: String
    let channelNumber: String
    let error: String?
    let message: String?

    enum CodingKeys: String, CodingKey {
        case success
        case tunerId
        case playlistUrl
        case channelNumber
        case error
        case message
    }
}

// Response from /api/live/heartbeat and /api/live/stop
struct LiveTVResponse: Codable {
    let success: Bool
    let message: String
}

// MARK: - Guide number ordering

extension Channel {
    /// Orders HDHomeRun guide numbers numerically by major then minor part,
    /// so "2.1" < "11.1" < "115" < "115.2". Non-numeric values sort after
    /// numeric ones using a natural string comparison.
    nonisolated static func compareGuideNumbers(_ a: String, _ b: String) -> Bool {
        func parse(_ value: String) -> (major: Int, minor: Int)? {
            let parts = value.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
            guard let first = parts.first, let major = Int(first) else { return nil }
            if parts.count > 1 {
                guard let minor = Int(parts[1]) else { return nil }
                return (major, minor)
            }
            return (major, 0)
        }

        switch (parse(a), parse(b)) {
        case let (lhs?, rhs?):
            return lhs.major != rhs.major ? lhs.major < rhs.major : lhs.minor < rhs.minor
        case (.some, .none):
            return true
        case (.none, .some):
            return false
        case (.none, .none):
            return a.localizedStandardCompare(b) == .orderedAscending
        }
    }

    nonisolated static func guideNumberAscending(_ lhs: Channel, _ rhs: Channel) -> Bool {
        compareGuideNumbers(lhs.guideNumber, rhs.guideNumber)
    }
}
