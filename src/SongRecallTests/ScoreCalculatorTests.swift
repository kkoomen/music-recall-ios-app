import XCTest
@testable import SongRecall

final class ScoreCalculatorTests: XCTestCase {
    func testImmediateAnswerScoresMaximum() {
        XCTAssertEqual(ScoreCalculator.score(forCorrectAnswerAt: 0), 1_000)
        XCTAssertEqual(ScoreCalculator.score(forCorrectAnswerAt: 0.001), 1_000)
    }

    func testOneSecondScoresNineSeventy() {
        XCTAssertEqual(ScoreCalculator.score(forCorrectAnswerAt: 1), 970)
        XCTAssertEqual(ScoreCalculator.score(forCorrectAnswerAt: 1.9), 970)
    }

    func testFifteenSecondsScoresFiveFifty() {
        XCTAssertEqual(ScoreCalculator.score(forCorrectAnswerAt: 15), 550)
    }

    func testThirtySecondsScoresMinimum() {
        XCTAssertEqual(ScoreCalculator.score(forCorrectAnswerAt: 30), 100)
        XCTAssertEqual(ScoreCalculator.score(forCorrectAnswerAt: 30.999), 100)
    }

    func testOverThirtySecondsClampsToMinimum() {
        XCTAssertEqual(ScoreCalculator.score(forCorrectAnswerAt: 31), 100)
        XCTAssertEqual(ScoreCalculator.score(forCorrectAnswerAt: 60), 100)
    }

    func testSubSecondFloorBoundaries() {
        XCTAssertEqual(ScoreCalculator.score(forCorrectAnswerAt: 0.999), 1_000)
        XCTAssertEqual(ScoreCalculator.score(forCorrectAnswerAt: 29.999), 130)
        XCTAssertEqual(ScoreCalculator.score(forCorrectAnswerAt: 29.99), 130)
    }

    func testNegativeElapsedClampsToImmediate() {
        XCTAssertEqual(ScoreCalculator.score(forCorrectAnswerAt: -5), 1_000)
    }

    func testZeroPointsForNonCorrectOutcomes() {
        XCTAssertEqual(ScoreCalculator.score(for: .wrong), 0)
        XCTAssertEqual(ScoreCalculator.score(for: .skipped), 0)
        XCTAssertEqual(ScoreCalculator.score(for: .timedOut), 0)
        XCTAssertEqual(ScoreCalculator.score(for: .interrupted), 0)
    }

    func testScoreFreezesAtFirstTerminalEvent() {
        var session = QuizSession(
            configuration: QuizConfiguration(roundCount: 1, roundDuration: 30),
            rounds: [QuizRound(track: Track(
                id: 1, title: "One", artist: "Artist", album: "Album",
                assetURL: URL(string: "ipod-library://item/item.mp3?id=1")!
            ))]
        )
        _ = session.begin(now: 0)
        _ = session.submitAnswer("One", now: 3)
        let first = session.currentRound?.outcome
        XCTAssertEqual(first, .correct(elapsed: 3))
        // Duplicate submission after terminal state cannot change the score.
        XCTAssertNil(session.submitAnswer("One", now: 4))
        XCTAssertNil(session.markTimedOutIfNeeded(now: 100))
        XCTAssertEqual(ScoreCalculator.score(for: session.currentRound!.outcome!), 910)
    }

    func testTimerCannotScoreAfterAnswerLandsFirst() {
        var session = QuizSession(
            configuration: QuizConfiguration(roundCount: 1, roundDuration: 30),
            rounds: [QuizRound(track: Track(
                id: 1, title: "One", artist: "Artist", album: "Album",
                assetURL: URL(string: "ipod-library://item/item.mp3?id=1")!
            ))]
        )
        _ = session.begin(now: 0)
        _ = session.submitAnswer("One", now: 5)   // answer wins the race
        XCTAssertNil(session.markTimedOutIfNeeded(now: 31)) // timer arrives late
        XCTAssertEqual(session.currentRound?.outcome, .correct(elapsed: 5))
        XCTAssertEqual(ScoreCalculator.score(for: session.currentRound!.outcome!), 850)
    }

    func testTimeoutArrivingFirstBlocksLaterAnswer() {
        var session = QuizSession(
            configuration: QuizConfiguration(roundCount: 1, roundDuration: 30),
            rounds: [QuizRound(track: Track(
                id: 1, title: "One", artist: "Artist", album: "Album",
                assetURL: URL(string: "ipod-library://item/item.mp3?id=1")!
            ))]
        )
        _ = session.begin(now: 0)
        XCTAssertEqual(session.markTimedOutIfNeeded(now: 30.001), .timedOut)
        XCTAssertNil(session.submitAnswer("One", now: 30.002))
        XCTAssertEqual(ScoreCalculator.score(for: session.currentRound!.outcome!), 0)
    }

    func testTotalScoreSumsRounds() {
        let url = URL(string: "ipod-library://item/item.mp3?id=1")!
        func track(_ id: UInt64) -> Track {
            Track(id: id, title: "T\(id)", artist: "A", album: "B", assetURL: url)
        }
        var session = QuizSession(
            configuration: QuizConfiguration(roundCount: 3, roundDuration: 30),
            rounds: [track(1), track(2), track(3)].map { QuizRound(track: $0) }
        )
        _ = session.begin(now: 0)
        _ = session.submitAnswer("T1", now: 0)   // 1000
        _ = session.advance(now: 1)
        _ = session.submitAnswer("T2", now: 16)  // 550
        _ = session.advance(now: 20)
        _ = session.skip()                        // 0
        let state = session.advance(now: 25)

        guard case .finished(let result) = state else {
            return XCTFail("Expected finished")
        }
        XCTAssertEqual(result.totalScore, 1_550)
    }
}
