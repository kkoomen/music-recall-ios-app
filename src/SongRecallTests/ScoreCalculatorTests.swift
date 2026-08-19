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

    func testAnswerAtFiveSecondsStillFast() {
        // "Within 5 seconds" includes exactly 5 (25 seconds remaining).
        let breakdown = ScoreCalculator.breakdown(forCorrectAnswerAt: 5)
        XCTAssertEqual(breakdown.points, 70) // 25 remaining, doubled
        XCTAssertTrue(breakdown.isFast)
    }

    func testAnswerJustOverFastWindowLosesMultiplier() {
        let breakdown = ScoreCalculator.breakdown(forCorrectAnswerAt: 5.01)
        XCTAssertEqual(breakdown.points, 35) // 25 remaining, no multiplier
        XCTAssertFalse(breakdown.isFast)
    }

    func testMidRoundScores() {
        XCTAssertEqual(ScoreCalculator.score(forCorrectAnswerAt: 10), 30) // 20 remaining
        XCTAssertEqual(ScoreCalculator.score(forCorrectAnswerAt: 15), 25) // 15 remaining
        XCTAssertEqual(ScoreCalculator.score(forCorrectAnswerAt: 20), 20) // 10 remaining
        XCTAssertEqual(ScoreCalculator.score(forCorrectAnswerAt: 29), 11) // 1 remaining
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

    // MARK: - Easy mode: 2x within the first 3 seconds

    func testEasyThresholdAnswerAtThreeSecondsIsFast() {
        // 27 seconds remaining on the clock -> doubled.
        let breakdown = ScoreCalculator.breakdown(
            forCorrectAnswerAt: 3,
            roundDuration: 30,
            fastThreshold: 3
        )
        XCTAssertEqual(breakdown.points, (10 + 27) * 2)
        XCTAssertTrue(breakdown.isFast)
    }

    func testEasyThresholdJustOverThreeSecondsLosesMultiplier() {
        let breakdown = ScoreCalculator.breakdown(
            forCorrectAnswerAt: 3.01,
            roundDuration: 30,
            fastThreshold: 3
        )
        XCTAssertEqual(breakdown.points, 10 + 27)
        XCTAssertFalse(breakdown.isFast)
    }

    func testEasyThresholdDoesNotAffectHardModeDefaults() {
        // The default fast threshold stays 5 seconds.
        XCTAssertEqual(ScoreCalculator.score(forCorrectAnswerAt: 4), 72)
        XCTAssertTrue(ScoreCalculator.breakdown(forCorrectAnswerAt: 4).isFast)
    }

    func testScoreForOutcomeUsesFastThreshold() {
        // 4 seconds: inside the hard-mode window, outside the easy one.
        XCTAssertEqual(
            ScoreCalculator.score(for: .correct(elapsed: 4), roundDuration: 30, fastThreshold: 3),
            36
        )
        XCTAssertEqual(
            ScoreCalculator.score(for: .correct(elapsed: 4), roundDuration: 30, fastThreshold: 5),
            72
        )
    }

    func testQuizConfigurationThresholdsFollowMode() {
        XCTAssertEqual(QuizConfiguration(mode: .easy).fastThreshold, 3)
        XCTAssertEqual(QuizConfiguration(mode: .hard).fastThreshold, 5)
        XCTAssertEqual(QuizConfiguration().fastThreshold, 5)
    }

    func testEasySessionTotalUsesThreeSecondThreshold() {
        // Easy mode: correct at 4s -> 26 remaining, no multiplier -> 36.
        // The same answer in hard mode would score 72.
        let url = URL(string: "ipod-library://item/item.mp3?id=1")!
        var session = QuizSession(
            configuration: QuizConfiguration(roundCount: 1, roundDuration: 30, mode: .easy),
            rounds: [QuizRound(track: Track(
                id: 1, title: "One", artist: "Artist", album: "Album", assetURL: url
            ))]
        )
        _ = session.begin(now: 0)
        _ = session.submitOption(trackID: 1, now: 4)
        let state = session.advance(now: 5)
        guard case .finished(let result) = state else {
            return XCTFail("Expected finished")
        }
        XCTAssertEqual(result.totalScore, 36)
        XCTAssertEqual(result.fastThreshold, 3)
    }

    // MARK: - Fast multiplier count on results

    func testFastCountCountsOnlyFastCorrectAnswers() {
        let url = URL(string: "ipod-library://item/item.mp3?id=1")!
        func track(_ id: UInt64) -> Track {
            Track(id: id, title: "T\(id)", artist: "A", album: "B", assetURL: url)
        }
        var session = QuizSession(
            configuration: QuizConfiguration(roundCount: 3, roundDuration: 30),
            rounds: [track(1), track(2), track(3)].map { QuizRound(track: $0) }
        )
        _ = session.begin(now: 0)
        _ = session.submitAnswer("T1", now: 0)   // fast: 2x
        _ = session.advance(now: 1)
        _ = session.submitAnswer("T2", now: 16)  // slow: no 2x
        _ = session.advance(now: 20)
        _ = session.submitAnswer("nope", now: 25) // wrong
        let state = session.advance(now: 26)

        guard case .finished(let result) = state else {
            return XCTFail("Expected finished")
        }
        XCTAssertEqual(result.correctCount, 2)
        XCTAssertEqual(result.fastCount, 1)
    }

    func testFastCountZeroWhenNothingIsFast() {
        let url = URL(string: "ipod-library://item/item.mp3?id=1")!
        var session = QuizSession(
            configuration: QuizConfiguration(roundCount: 1, roundDuration: 30),
            rounds: [QuizRound(track: Track(
                id: 1, title: "One", artist: "Artist", album: "Album", assetURL: url
            ))]
        )
        _ = session.begin(now: 0)
        _ = session.submitAnswer("One", now: 20) // 20s: no 2x
        let state = session.advance(now: 21)
        guard case .finished(let result) = state else {
            return XCTFail("Expected finished")
        }
        XCTAssertEqual(result.fastCount, 0)
    }

    func testFastCountRespectsEasyModeThreshold() {
        // Easy: correct at exactly 3s is fast, at 4s it is not.
        let url = URL(string: "ipod-library://item/item.mp3?id=1")!
        func track(_ id: UInt64) -> Track {
            Track(id: id, title: "T\(id)", artist: "A", album: "B", assetURL: url)
        }
        var session = QuizSession(
            configuration: QuizConfiguration(roundCount: 2, roundDuration: 30, mode: .easy),
            rounds: [track(1), track(2)].map { QuizRound(track: $0) }
        )
        _ = session.begin(now: 0)
        _ = session.submitOption(trackID: 1, now: 3)  // fast in easy mode
        _ = session.advance(now: 4)
        _ = session.submitOption(trackID: 2, now: 8)  // 4s elapsed: not fast
        let state = session.advance(now: 9)
        guard case .finished(let result) = state else {
            return XCTFail("Expected finished")
        }
        XCTAssertEqual(result.fastCount, 1)
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
        XCTAssertEqual(ScoreCalculator.score(for: session.currentRound!.outcome!), 70)
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
        _ = session.submitAnswer("T1", now: 25)  // 25s: no multiplier -> 15
        _ = session.advance(now: 26)
        _ = session.skip()                        // -10
        let state = session.advance(now: 27)

        guard case .finished(let result) = state else {
            return XCTFail("Expected finished")
        }
        XCTAssertEqual(result.totalScore, 5) // 15 - 10, above the floor
    }
}
