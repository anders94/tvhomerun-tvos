//
//  EpisodeSorting.swift
//  TVHomeRun
//
//  Season grouping and date ordering for recorded episodes
//

import Foundation

nonisolated enum SeasonSortOrder: String, CaseIterable, Identifiable {
    case descending
    case ascending

    var id: Self { self }

    var title: String {
        switch self {
        case .descending: "Latest First"
        case .ascending: "Earliest First"
        }
    }
}

nonisolated enum EpisodeDateOrder: String, CaseIterable, Identifiable {
    case newestFirst
    case oldestFirst

    var id: Self { self }

    var title: String {
        switch self {
        case .newestFirst: "Newest First"
        case .oldestFirst: "Oldest First"
        }
    }
}

nonisolated enum SeasonKey: Hashable, Identifiable {
    case season(Int)
    case specials

    var id: String {
        switch self {
        case .season(let number): "season-\(number)"
        case .specials: "specials"
        }
    }

    var title: String {
        switch self {
        case .season(let number): "Season \(number)"
        case .specials: "Specials"
        }
    }
}

struct SeasonGroup: Identifiable {
    let key: SeasonKey
    let episodes: [Episode]

    var id: SeasonKey { key }
}

enum SortPreferenceKey {
    static let seasonOrder = "sort.seasonOrder"
    static let episodeOrder = "sort.episodeOrder"
}

extension Episode {
    private static let isoWithFraction: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let iso = ISO8601DateFormatter()

    /// Primary date sort key: when the recording was made, falling back to
    /// the original air date and then the scheduled start time.
    var sortTimestamp: Int {
        if recordStartTime > 0 { return recordStartTime }
        for candidate in [originalAirdate, startTime] {
            if let date = Self.isoWithFraction.date(from: candidate) ?? Self.iso.date(from: candidate) {
                return Int(date.timeIntervalSince1970)
            }
        }
        return 0
    }

    /// Episode title, falling back to the program title when the episode has none.
    var displayTitle: String {
        episodeTitle.isEmpty ? title : episodeTitle
    }
}

extension Array where Element == Episode {
    /// Groups episodes by season number. Returns nil when no episode carries a
    /// season number, in which case the caller shows a flat list. Episodes
    /// without a season are collected under `.specials`, always listed last.
    func groupedBySeason(order: SeasonSortOrder) -> [SeasonGroup]? {
        let numbered = Dictionary(grouping: filter { $0.seasonNumber != nil }) { $0.seasonNumber ?? 0 }
        guard !numbered.isEmpty else { return nil }

        let keys = order == .descending
            ? numbered.keys.sorted(by: >)
            : numbered.keys.sorted(by: <)
        var groups = keys.map { SeasonGroup(key: .season($0), episodes: numbered[$0] ?? []) }

        let specials = filter { $0.seasonNumber == nil }
        if !specials.isEmpty {
            groups.append(SeasonGroup(key: .specials, episodes: specials))
        }
        return groups
    }

    func sortedByDate(_ order: EpisodeDateOrder) -> [Episode] {
        sorted { a, b in
            if a.sortTimestamp != b.sortTimestamp {
                return order == .newestFirst
                    ? a.sortTimestamp > b.sortTimestamp
                    : a.sortTimestamp < b.sortTimestamp
            }
            let (ae, be) = (a.episodeNum ?? 0, b.episodeNum ?? 0)
            return order == .newestFirst ? ae > be : ae < be
        }
    }
}
