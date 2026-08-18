import Foundation

/// One autocomplete suggestion for the answer field.
struct TrackSuggestion: Equatable, Sendable {
    let track: Track
}

/// Ranks candidate tracks for the answer-field autocomplete.
///
/// Scores normalized text matches against title, artist, and the
/// artist-title form. Returns at most `limit` results, most relevant
/// first. Ties break alphabetically by title; the current round's track
/// receives a small boost when it matches.
///
/// For large catalogs, precompute an index once with `makeIndex(from:)`
/// and use the index-based `rank(query:index:...)` overload so metadata
/// normalization never repeats per keystroke.
enum TrackSuggestionRanker {
    /// Pre-normalized search entry for one track.
    struct IndexEntry: Sendable {
        let track: Track
        let title: String
        let artist: String
        let artistTitle: String
    }

    static func makeIndex(from tracks: [Track]) -> [IndexEntry] {
        tracks.map { track in
            IndexEntry(
                track: track,
                title: AnswerNormalizer.normalize(track.title),
                artist: AnswerNormalizer.normalize(track.artist),
                artistTitle: AnswerNormalizer.normalize("\(track.artist) \(track.title)")
            )
        }
    }

    /// Convenience overload that builds the index per call.
    static func rank(
        query: String,
        tracks: [Track],
        preferredTrackID: Track.ID? = nil,
        limit: Int = 5
    ) -> [TrackSuggestion] {
        rank(query: query, index: makeIndex(from: tracks), preferredTrackID: preferredTrackID, limit: limit)
    }

    static func rank(
        query: String,
        index: [IndexEntry],
        preferredTrackID: Track.ID? = nil,
        limit: Int = 5
    ) -> [TrackSuggestion] {
        let normalized = AnswerNormalizer.normalize(query)
        guard !normalized.isEmpty, limit > 0 else { return [] }

        let scored: [(track: Track, score: Int)] = index.compactMap { entry in
            var score = score(query: normalized, entry: entry)
            guard score > 0 else { return nil }
            if entry.track.id == preferredTrackID {
                score += 5
            }
            return (entry.track, score)
        }

        return scored
            .sorted { lhs, rhs in
                if lhs.score != rhs.score {
                    return lhs.score > rhs.score
                }
                return lhs.track.title.localizedCaseInsensitiveCompare(rhs.track.title)
                    == .orderedAscending
            }
            .prefix(limit)
            .map { TrackSuggestion(track: $0.track) }
    }

    /// Higher is better. Zero means no match.
    static func score(query: String, entry: IndexEntry) -> Int {
        if query == entry.title { return 100 }
        if entry.title.hasPrefix(query) { return 90 }
        if query == entry.artist { return 85 }
        if entry.artist.hasPrefix(query) { return 80 }
        if entry.artistTitle.hasPrefix(query) { return 75 }
        if entry.title.contains(query) { return 70 }
        if entry.artistTitle.contains(query) { return 60 }
        if entry.artist.contains(query) { return 50 }
        return 0
    }
}
