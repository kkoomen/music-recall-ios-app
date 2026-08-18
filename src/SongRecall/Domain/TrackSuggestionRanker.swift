import Foundation

/// One autocomplete suggestion for the answer field.
struct TrackSuggestion: Equatable, Sendable {
    let track: Track
}

/// Ranks candidate tracks for the answer-field autocomplete.
///
/// Scores normalized text matches against title, artist, and the
/// artist-title form. Returns at most `limit` results, most relevant
/// first. Songs with equal relevance — for example every song by one
/// artist — are shuffled randomly via the injected random source, so
/// the active round's track is never favored. No alphabetical fallback.
///
/// For large catalogs, precompute an index once with `makeIndex(from:)`
/// and use the index-based `rank(query:index:random:...)` overload so
/// metadata normalization never repeats per keystroke.
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
        random: RandomSource,
        limit: Int = 5
    ) -> [TrackSuggestion] {
        rank(query: query, index: makeIndex(from: tracks), random: random, limit: limit)
    }

    static func rank(
        query: String,
        index: [IndexEntry],
        random: RandomSource,
        limit: Int = 5
    ) -> [TrackSuggestion] {
        let normalized = AnswerNormalizer.normalize(query)
        guard !normalized.isEmpty, limit > 0 else { return [] }

        let scored = index.compactMap { entry -> (track: Track, score: Int)? in
            let score = score(query: normalized, entry: entry)
            return score > 0 ? (entry.track, score) : nil
        }

        // Group by score and shuffle inside each group, so ties (e.g.
        // every song by one artist) are listed at random.
        let grouped = Dictionary(grouping: scored, by: \.score)
        let scores = grouped.keys.sorted(by: >)

        return scores
            .flatMap { score in
                random.shuffled(grouped[score] ?? []).map(\.track)
            }
            .prefix(limit)
            .map { TrackSuggestion(track: $0) }
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
