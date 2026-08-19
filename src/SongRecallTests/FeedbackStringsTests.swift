import XCTest
@testable import SongRecall

/// Locks in the exact feedback wording, including interpolated point
/// values (a regression guard against literal \"(points)\" text).
final class FeedbackStringsTests: XCTestCase {
    func testCorrectNonFastShowsActualPoints() {
        XCTAssertEqual(
            FeedbackStrings.correct(points: 35, isFast: false),
            "Correct! +35 points"
        )
    }

    func testCorrectFastShowsMultiplierAndActualPoints() {
        XCTAssertEqual(
            FeedbackStrings.correct(points: 72, isFast: true),
            "You're fast! 2x, plus 72 points"
        )
    }

    func testWrongShowsPenalty() {
        XCTAssertEqual(FeedbackStrings.wrong(points: -5), "Not this time (-5)")
    }

    func testSkippedShowsPenalty() {
        XCTAssertEqual(FeedbackStrings.skipped(points: -10), "Skipped (-10)")
    }

    func testTimeoutAndInterruptionMessages() {
        XCTAssertEqual(FeedbackStrings.timedOut, "Time's up")
        XCTAssertEqual(FeedbackStrings.interrupted, "Playback was interrupted")
    }
}
