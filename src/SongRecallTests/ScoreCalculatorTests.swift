import XCTest
@testable import SongRecall

final class ScoreCalculatorTests: XCTestCase {
    // MARK: - Formula: (10 + remaining seconds) x multiplier, 2x within 5s

    func testImmediateAnswerIsFastAndScoresEighty() {
        let breakdown = ScoreCalculator.breakdown(forCorrectAnswerAt: 0)
        XCTAssertEqual(breakdown.points, 80)
        XCTAssertTrue(breakdown.isFast)
    }

    func testSubSecondAnswerStillCountsAsImmediate() {
        let breakdown = ScoreCalculator.breakdown(forCorrectAnswerAt: 0.999)
        XCTAssertEqual(breakdown.points, 80)
        XCTAssertTrue(breakdown.isFast)
    }

    func testOneSecondScoresSeventyEight() {
        let breakdown = ScoreCalculator.breakdown(forCorrectAnswerAt: 1)
        XCTAssertEqual(breakdown.points, 78)
        XCTAssertTrue(breakdown.isFast)
        // Partial seconds do not cost points: 1.9s counts as 1 full second.
        XCTAssertEqual(ScoreCalculator.score(forCorrectAnswerAt: 1.9), 78)
    }

    func testAnswerJustInsideFastWindow() {
        let breakdown = ScoreCalculator.breakdown(forCorrectAnswerAt: 4.99)
        XCTAssertEqual(breakdown.points, 72) // 26 remaining, doubled
        XCTAssertTrue(breakdown.isFast)
    }

    func testAnswerAtFiveSecondsLosesMultiplier() {
        let breakdown = ScoreCalculator.breakdown(forCorrectAnswerAt: 5)
        XCTAssertEqual(breakdown.points, 35) // 25 remaining, no multiplier
        XCTAssertFalse(breakdown.isFast)
    }

    func testMidRoundScores() {
        XCTAssertEqual(ScoreCalculator.score(forCorrectAnswerAt: 10), 30) // 20 remaining
        XCTAssertEqual(ScoreCalculator.score(forCorrectAnswerAt: 15), 25) // 15 remaining
        XCTAssertEqual(ScoreCalculator.score(forCorrectAnswerAt: 20), 20) // 10 remaining
        XCTAssertEqual(ScoreCalculator.score(forCorrectAnswerAt: 25), 15) //  5 remaining
    }

    func testAnswerNearTheEndOfRound() {
        XCTAssertEqual(ScoreCalculator.score(forCorrectAnswerAt: 29), 11)   // 1 remaining
        XCTAssertEqual(ScoreCalculator.score(forCorrectAnswerAt: 29.99), 11)
    }

    func testAnswerAtThirtySecondsScoresBaseOnly() {
        let breakdown = ScoreCalculator.breakdown(forCorrectAnswerAt: 30)
        XCTAssertEqual(breakdown.points, 10)
        XCTAssertFalse(breakdown.isFast)
    }

    func testOverThirtySecondsClampsToBase() {
        XCTAssertEqual(ScoreCalculator.score(forCorrectAnswerAt: 30.5), 10)
        XCTAssertEqual(ScoreCalculator.score(forCorrectAnswerAt: 31), 10)
    }

    func testNegativeElapsedClampsToImmediateFast() {
        let breakdown = ScoreCalculator.breakdown(forCorrectAnswerAt: -5)
        XCTAssertEqual(breakdown.points, 80)
        XCTAssertTrue(breakdown.isFast)
    }

    func testPenaltiesForNonCorrectOutcomes() {
        XCTAssertEqual(ScoreCalculator.score(for: .wrong), -5)
        XCTAssertEqual(ScoreCalculator.score(for: .skipped), -10)
        XCTAssertEqual(ScoreCalculator.score(for: .timedOut), 0)
        XCTAssertEqual(ScoreCalculator.score(for: .interrupted), 0)
    }

    func testCustomRoundDurationUsesItsOwnRemaining() {
        // 2-second round: answer at 0.5s -> 2 remaining, fast.
        let breakdown = ScoreCalculator.breakdown(
            forCorrectAnswerAt: 0.5,
            roundDuration: 2
        )
        XCTAssertEqual(breakdown.points, (10 + 2) * 2)
        XCTAssertTrue(breakdown.isFast)
    }

    // MARK: - Freeze and timer races

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
        XCTAssertEqual(ScoreCalculator.score(for: session.currentRound!.outcome!), 74)
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
        XCTAssertEqual(ScoreCalculator.score(for: session.currentRound!.outcome!), 35)
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
        _ = session.submitAnswer("T1", now: 0)   // fast: 80
        _ = session.advance(now: 1)
        _ = session.submitAnswer("T2", now: 16)  // elapsed 15 -> 15 remaining: 25
        _ = session.advance(now: 20)
        _ = session.skip()                        // -10
        let state = session.advance(now: 25)

        guard case .finished(let result) = state else {
            return XCTFail("Expected finished")
        }
        XCTAssertEqual(result.totalScore, 95) // 80 + 25 - 10
        XCTAssertEqual(result.roundDuration, 30)
    }

    func testTotalScoreCannotGoBelowZero() {
        let url = URL(string: "ipod-library://item/item.mp3?id=1")!
        func track(_ id: UInt64) -> Track {
            Track(id: id, title: "T\(id)", artist: "A", album: "B", assetURL: url)
        }
        var session = QuizSession(
            configuration: QuizConfiguration(roundCount: 3, roundDuration: 30),
            rounds: [track(1), track(2), track(3)].map { QuizRound(track: $0) }
        )
        _ = session.begin(now: 0)
        _ = session.skip()
        _ = session.advance(now: 1)
        _ = session.skip()
        _ = session.advance(now: 2)
        _ = session.skip()
        let state = session.advance(now: 3)

        guard case .finished(let result) = state else {
            return XCTFail("Expected finished")
        }
        XCTAssertEqual(result.totalScore, 0) // -30 clamps to 0
    }

    func testMixedScoreClampsAtZero() {
        let url = URL(string: "ipod-library://item/item.mp3?id=1")!
        func track(_ id: UInt64) -> Track {
            Track(id: id, title: "T\(id)", artist: "A", album: "B", assetURL: url)
        }
        var session = QuizSession(
            configuration: QuizConfiguration(roundCount: 2, roundDuration: 30),
            rounds: [track(1), track(2)].map { QuizRound(track: $0) }
        )
        _ = session.begin(now: 0)
        _ = session.submitAnswer("T1", now: 25)  // 15 points
        _ = session.advance(now: 26)
        _ = session.skip()                        // -10
        let state = session.advance(now: 27)

        guard case .finished(let result) = state else {
            return XCTFail("Expected finished")
        }
        XCTAssertEqual(result.totalScore, 5) // 15 - 10 = 5, above the floor
    }
}
