import XCTest
@testable import SongRecall

/// Deterministic fake sources for testing tie-shuffling without
/// depending on a specific seeded shuffle outcome.
private struct IdentityRandomSource: RandomSource {
    func shuffled<T>(_ elements: [T]) -> [T] { elements }
    func nextDouble() -> Double { 0 }
}

private struct ReversingRandomSource: RandomSource {
    func shuffled<T>(_ elements: [T]) -> [T] { elements.reversed() }
    func nextDouble() -> Double { 0.5 }
}

final class TrackSuggestionRankerTests: XCTestCase {
    private let url = URL(string: "ipod-library://item/item.mp3?id=1")!

    private func track(_ id: UInt64, _ title: String, _ artist: String = "Artist") -> Track {
        Track(id: id, title: title, artist: artist, album: "Album", assetURL: url)
    }

    func testEmptyQueryReturnsNoSuggestions() {
        XCTAssertTrue(
            TrackSuggestionRanker.rank(query: "", tracks: [track(1, "Alpha")], random: IdentityRandomSource()).isEmpty
        )
        XCTAssertTrue(
            TrackSuggestionRanker.rank(query: "   ", tracks: [track(1, "Alpha")], random: IdentityRandomSource()).isEmpty
        )
    }

    func testExactTitleMatchRanksFirst() {
        let tracks = [
            track(1, "Bohemian Rhapsody"),
            track(2, "Bohemian", "Bohemian Rhapsody Band"),
        ]
        let results = TrackSuggestionRanker.rank(
            query: "Bohemian Rhapsody",
            tracks: tracks,
            random: IdentityRandomSource()
        )
        XCTAssertEqual(results.first?.track.id, 1)
    }

    func testTitlePrefixBeatsSubstring() {
        let tracks = [
            track(1, "The Bohemian"),
            track(2, "Bohemian Rhapsody"),
        ]
        let results = TrackSuggestionRanker.rank(query: "bo", tracks: tracks, random: IdentityRandomSource())
        XCTAssertEqual(results.map(\.track.id), [2, 1])
    }

    func testArtistPrefixMatches() {
        let tracks = [
            track(1, "Another One", "Quiet Riot"),
            track(2, "Bohemian Rhapsody", "Queen"),
        ]
        let results = TrackSuggestionRanker.rank(query: "que", tracks: tracks, random: IdentityRandomSource())
        XCTAssertEqual(results.map(\.track.id), [2])
    }

    func testArtistTitlePrefixMatches() {
        let tracks = [
            track(1, "Some Song", "Queen"),
            track(2, "Bohemian Rhapsody", "Queen"),
        ]
        let results = TrackSuggestionRanker.rank(
            query: "queen bohe",
            tracks: tracks,
            random: IdentityRandomSource()
        )
        XCTAssertEqual(results.first?.track.id, 2)
    }

    func testLimitIsRespected() {
        let tracks = (1...8).map { track(UInt64($0), "A Song \($0)") }
        let results = TrackSuggestionRanker.rank(
            query: "a song",
            tracks: tracks,
            random: SeededRandomSource(seed: 0)
        )
        XCTAssertEqual(results.count, 5)
    }

    func testNormalizationAppliesToQueryAndMetadata() {
        let tracks = [track(1, "Café au Lait")]
        let results = TrackSuggestionRanker.rank(query: "cafe", tracks: tracks, random: IdentityRandomSource())
        XCTAssertEqual(results.first?.track.id, 1)
    }

    func testNoMatchReturnsEmpty() {
        let tracks = [track(1, "Zebra")]
        XCTAssertTrue(
            TrackSuggestionRanker.rank(query: "xyzzy", tracks: tracks, random: IdentityRandomSource()).isEmpty
        )
    }

    // MARK: - Tie ordering is random, never alphabetical and never favored

    func testEqualScoreSongsFollowInjectedRandomSource() {
        // Two songs by the same artist match with equal relevance.
        let tracks = [
            track(1, "Aardvark Song", "Queen"),
            track(2, "Zebra Song", "Queen"),
        ]
        let identity = TrackSuggestionRanker.rank(
            query: "Queen",
            tracks: tracks,
            random: IdentityRandomSource()
        )
        XCTAssertEqual(identity.map(\.track.id), [1, 2])

        let reversed = TrackSuggestionRanker.rank(
            query: "Queen",
            tracks: tracks,
            random: ReversingRandomSource()
        )
        XCTAssertEqual(reversed.map(\.track.id), [2, 1])
    }

    func testSameSeedProducesSameTieOrder() {
        let tracks = [
            track(1, "Aardvark Song", "Queen"),
            track(2, "Zebra Song", "Queen"),
            track(3, "Middle Song", "Queen"),
        ]
        let a = TrackSuggestionRanker.rank(query: "Queen", tracks: tracks, random: SeededRandomSource(seed: 7))
        let b = TrackSuggestionRanker.rank(query: "Queen", tracks: tracks, random: SeededRandomSource(seed: 7))
        XCTAssertEqual(a.map(\.track.id), b.map(\.track.id))
    }

    func testSeededSourceProducesNonAlphabeticalOrderAtLeastOnce() {
        // Across a handful of seeds, equal-score songs must not stay
        // pinned to alphabetical order (the old behavior).
        let tracks = [
            track(1, "Aardvark Song", "Queen"),
            track(2, "Zebra Song", "Queen"),
        ]
        let orders = Set((0..<12).map { seed in
            TrackSuggestionRanker.rank(query: "Queen", tracks: tracks, random: SeededRandomSource(seed: UInt64(seed)))
                .map(\.track.id)
        })
        // Both possible orders occur across seeds, proving randomization
        // rather than a fixed alphabetical sort.
        XCTAssertEqual(orders.count, 2)
    }

    func testNoPreferenceForAnyParticularTrack() {
        // The ranker has no concept of an active round: with a fixed
        // identity source the catalog order is preserved, and nothing in
        // the API can promote a specific track.
        let tracks = [
            track(1, "Alpha Song", "Artist"),
            track(2, "Beta Song", "Artist"),
        ]
        let result = TrackSuggestionRanker.rank(query: "Artist", tracks: tracks, random: IdentityRandomSource())
        XCTAssertEqual(result.map(\.track.id), [1, 2])
    }
}
