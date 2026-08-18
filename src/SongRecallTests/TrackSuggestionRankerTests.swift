import XCTest
@testable import SongRecall

final class TrackSuggestionRankerTests: XCTestCase {
    private let url = URL(string: "ipod-library://item/item.mp3?id=1")!

    private func track(_ id: UInt64, _ title: String, _ artist: String = "Artist") -> Track {
        Track(id: id, title: title, artist: artist, album: "Album", assetURL: url)
    }

    func testEmptyQueryReturnsNoSuggestions() {
        XCTAssertTrue(TrackSuggestionRanker.rank(query: "", tracks: [track(1, "Alpha")]).isEmpty)
        XCTAssertTrue(TrackSuggestionRanker.rank(query: "   ", tracks: [track(1, "Alpha")]).isEmpty)
    }

    func testExactTitleMatchRanksFirst() {
        let tracks = [
            track(1, "Bohemian Rhapsody"),
            track(2, "Bohemian",
                 "Bohemian Rhapsody Band"),
        ]
        let results = TrackSuggestionRanker.rank(query: "Bohemian Rhapsody", tracks: tracks)
        XCTAssertEqual(results.first?.track.id, 1)
    }

    func testTitlePrefixBeatsSubstring() {
        let tracks = [
            track(1, "The Bohemian"),
            track(2, "Bohemian Rhapsody"),
        ]
        let results = TrackSuggestionRanker.rank(query: "bo", tracks: tracks)
        XCTAssertEqual(results.map(\.track.id), [2, 1])
    }

    func testArtistPrefixMatches() {
        let tracks = [
            track(1, "Another One", "Quiet Riot"),
            track(2, "Bohemian Rhapsody", "Queen"),
        ]
        let results = TrackSuggestionRanker.rank(query: "que", tracks: tracks)
        XCTAssertEqual(results.map(\.track.id), [2])
    }

    func testArtistTitlePrefixMatches() {
        let tracks = [
            track(1, "Some Song", "Queen"),
            track(2, "Bohemian Rhapsody", "Queen"),
        ]
        let results = TrackSuggestionRanker.rank(query: "queen bohe", tracks: tracks)
        XCTAssertEqual(results.first?.track.id, 2)
    }

    func testLimitIsRespected() {
        let tracks = (1...8).map { track(UInt64($0), "A Song \($0)") }
        let results = TrackSuggestionRanker.rank(query: "a song", tracks: tracks)
        XCTAssertEqual(results.count, 5)
    }

    func testPreferredTrackWinsTie() {
        let tracks = [
            track(1, "Billie Jean"),
            track(2, "Bohemian Rhapsody"),
        ]
        let results = TrackSuggestionRanker.rank(
            query: "b",
            tracks: tracks,
            preferredTrackID: 1
        )
        XCTAssertEqual(results.first?.track.id, 1)
    }

    func testTieBreaksAlphabeticallyWithoutPreference() {
        let tracks = [
            track(1, "Zebra Song"),
            track(2, "Alpha Song"),
            track(3, "Banana Song"),
        ]
        let results = TrackSuggestionRanker.rank(query: "b", tracks: tracks)
        XCTAssertEqual(results.map(\.track.id), [3, 1])
    }

    func testNormalizationAppliesToQueryAndMetadata() {
        let tracks = [track(1, "Café au Lait")]
        let results = TrackSuggestionRanker.rank(query: "cafe", tracks: tracks)
        XCTAssertEqual(results.first?.track.id, 1)
    }

    func testNoMatchReturnsEmpty() {
        let tracks = [track(1, "Zebra")]
        XCTAssertTrue(TrackSuggestionRanker.rank(query: "xyzzy", tracks: tracks).isEmpty)
    }
}
