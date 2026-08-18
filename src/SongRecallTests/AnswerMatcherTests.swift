import XCTest
@testable import SongRecall

final class AnswerMatcherTests: XCTestCase {
    private let track = Track(
        id: 1,
        title: "Bohemian Rhapsody",
        artist: "Queen",
        album: "A Night at the Opera",
        assetURL: URL(string: "ipod-library://item/item.mp3?id=1")!
    )

    func testExactTitleMatches() {
        XCTAssertTrue(AnswerMatcher.isMatch(guess: "Bohemian Rhapsody", track: track))
    }

    func testNormalizedTitleMatches() {
        XCTAssertTrue(AnswerMatcher.isMatch(guess: "  bohemian   rhapsody!!! ", track: track))
    }

    func testArtistTitleFormMatches() {
        XCTAssertTrue(AnswerMatcher.isMatch(guess: "Queen - Bohemian Rhapsody", track: track))
        XCTAssertTrue(AnswerMatcher.isMatch(guess: "queen bohemian rhapsody", track: track))
    }

    func testWrongAnswerDoesNotMatch() {
        XCTAssertFalse(AnswerMatcher.isMatch(guess: "Another One Bites the Dust", track: track))
    }

    func testEmptyOrWhitespaceGuessDoesNotMatch() {
        XCTAssertFalse(AnswerMatcher.isMatch(guess: "", track: track))
        XCTAssertFalse(AnswerMatcher.isMatch(guess: "   ", track: track))
    }
}
