//
//  Episode.swift
//  TVHomeRun
//
//  Data model for TV episodes
//

import Foundation

struct EpisodesResponse: Codable {
    let episodes: [Episode]
    let count: Int
    let show: ShowInfo
}

struct ShowInfo: Codable {
    let id: Int
    let seriesId: String
    let title: String

    enum CodingKeys: String, CodingKey {
        case id
        case seriesId = "series_id"
        case title
    }
}

struct Episode: Codable, Identifiable {
    let id: Int
    let programId: String
    let title: String
    let episodeTitle: String
    let episodeNumber: String
    let seasonNumber: Int
    let episodeNum: Int
    let synopsis: String
    let category: String
    let channelName: String
    let channelNumber: String
    let channelImageUrl: String?
    let startTime: String
    let endTime: String
    let duration: Int
    let originalAirdate: String
    let recordStartTime: Int
    let recordEndTime: Int
    let firstAiring: Int
    let filename: String
    let fileSize: Int?
    let playUrl: String
    let cmdUrl: String
    let resumePosition: Int?
    let watched: Int
    let recordSuccess: Int
    let imageUrl: String?
    let createdAt: String
    let updatedAt: String
    let seriesId: String
    let seriesTitle: String
    let durationMinutes: Int
    let resumeMinutes: Int

    enum CodingKeys: String, CodingKey {
        case id
        case programId = "program_id"
        case title
        case episodeTitle = "episode_title"
        case episodeNumber = "episode_number"
        case seasonNumber = "season_number"
        case episodeNum = "episode_num"
        case synopsis
        case category
        case channelName = "channel_name"
        case channelNumber = "channel_number"
        case channelImageUrl = "channel_image_url"
        case startTime = "start_time"
        case endTime = "end_time"
        case duration
        case originalAirdate = "original_airdate"
        case recordStartTime = "record_start_time"
        case recordEndTime = "record_end_time"
        case firstAiring = "first_airing"
        case filename
        case fileSize = "file_size"
        case playUrl = "play_url"
        case cmdUrl = "cmd_url"
        case resumePosition = "resume_position"
        case watched
        case recordSuccess = "record_success"
        case imageUrl = "image_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case seriesId = "series_id"
        case seriesTitle = "series_title"
        case durationMinutes = "duration_minutes"
        case resumeMinutes = "resume_minutes"
    }

    var progressPercentage: Double {
        guard let resumePos = resumePosition, duration > 0 else { return 0 }
        return Double(resumePos) / Double(duration)
    }

    var isWatched: Bool {
        watched > 0
    }

    var formattedAirDate: String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: originalAirdate) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            return displayFormatter.string(from: date)
        }
        return originalAirdate
    }

    var formattedDuration: String {
        let minutes = durationMinutes
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            return "\(hours)h \(mins)m"
        }
        return "\(minutes)m"
    }
}
