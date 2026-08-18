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
enum TrackSuggestionRanker {
    static func rank(
        query: String,
        tracks: [Track],
        preferredTrackID: Track.ID? = nil,
        limit: Int = 5
    ) -> [TrackSuggestion] {
        let normalized = AnswerNormalizer.normalize(query)
        guard !normalized.isEmpty, limit > 0 else { return [] }

        let scored: [(track: Track, score: Int)] = tracks.compactMap { track in
            var score = score(query: normalized, track: track)
            guard score > 0 else { return nil }
            if track.id == preferredTrackID {
                score += 5
            }
            return (track, score)
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
    static func score(query: String, track: Track) -> Int {
        let title = AnswerNormalizer.normalize(track.title)
        let artist = AnswerNormalizer.normalize(track.artist)
        let artistTitle = AnswerNormalizer.normalize("\(track.artist) \(track.title)")

        if query == title { return 100 }
        if title.hasPrefix(query) { return 90 }
        if query == artist { return 85 }
        if artist.hasPrefix(query) { return 80 }
        if artistTitle.hasPrefix(query) { return 75 }
        if title.contains(query) { return 70 }
        if artistTitle.contains(query) { return 60 }
        if artist.contains(query) { return 50 }
        return 0
    }
}
