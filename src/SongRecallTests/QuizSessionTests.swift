import XCTest
@testable import SongRecall

final class QuizSessionTests: XCTestCase {
    private let url = URL(string: "ipod-library://item/item.mp3?id=1")!

    private func makeTrack(id: UInt64, title: String, artist: String = "Artist") -> Track {
        Track(id: id, title: title, artist: artist, album: "Album", assetURL: url)
    }

    private func makeSession(tracks: [Track], duration: TimeInterval = 30) -> QuizSession {
        QuizSession(
            configuration: QuizConfiguration(roundCount: tracks.count, roundDuration: duration),
            rounds: tracks.map { QuizRound(track: $0) }
        )
    }

    func testBeginStartsFirstRound() {
        var session = makeSession(tracks: [makeTrack(id: 1, title: "One")])
        XCTAssertEqual(session.state, .notStarted)
        XCTAssertEqual(session.begin(now: 5), .playing(roundIndex: 0))
        XCTAssertEqual(session.currentRound?.startElapsed, 5)
    }

    func testBeginIsNoOpWhenAlreadyStarted() {
        var session = makeSession(tracks: [makeTrack(id: 1, title: "One")])
        _ = session.begin(now: 0)
        XCTAssertEqual(session.begin(now: 50), .playing(roundIndex: 0))
    }

    func testCorrectAnswerRecordsElapsed() {
        var session = makeSession(tracks: [makeTrack(id: 1, title: "One")])
        _ = session.begin(now: 0)
        let outcome = session.submitAnswer("One", now: 7.5)
        XCTAssertEqual(outcome, .correct(elapsed: 7.5))
        XCTAssertEqual(session.currentRound?.isCorrect, true)
    }

    func testWrongAnswerEndsRound() {
        var session = makeSession(tracks: [makeTrack(id: 1, title: "One")])
        _ = session.begin(now: 0)
        XCTAssertEqual(session.submitAnswer("Two", now: 2), .wrong)
        XCTAssertEqual(session.currentRound?.isActive, false)
    }

    // MARK: - Option submission (easy mode)

    func testSubmitOptionCorrectByTrackIdentity() {
        var session = makeSession(tracks: [makeTrack(id: 1, title: "One")])
        _ = session.begin(now: 0)
        XCTAssertEqual(session.submitOption(trackID: 1, now: 2.5), .correct(elapsed: 2.5))
        XCTAssertEqual(session.currentRound?.isCorrect, true)
    }

    func testSubmitOptionWrongByTrackIdentity() {
        var session = makeSession(tracks: [makeTrack(id: 1, title: "One")])
        _ = session.begin(now: 0)
        XCTAssertEqual(session.submitOption(trackID: 2, now: 2), .wrong)
        XCTAssertEqual(session.currentRound?.isActive, false)
    }

    func testSubmitOptionMatchesIdentityNotTitle() {
        // A decoy sharing the correct track's title must never count.
        var session = makeSession(tracks: [makeTrack(id: 2, title: "One")])
        _ = session.begin(now: 0)
        XCTAssertEqual(session.submitOption(trackID: 1, now: 1), .wrong)
    }

    func testSubmitOptionTimesOutAfterDuration() {
        var onTime = makeSession(tracks: [makeTrack(id: 1, title: "One")], duration: 30)
        _ = onTime.begin(now: 0)
        XCTAssertEqual(onTime.submitOption(trackID: 1, now: 30), .correct(elapsed: 30))

        var late = makeSession(tracks: [makeTrack(id: 1, title: "One")], duration: 30)
        _ = late.begin(now: 0)
        XCTAssertEqual(late.submitOption(trackID: 1, now: 30.001), .timedOut)
    }

    func testTerminalRoundRejectsOptions() {
        var session = makeSession(tracks: [makeTrack(id: 1, title: "One")])
        _ = session.begin(now: 0)
        _ = session.submitOption(trackID: 1, now: 1)
        XCTAssertNil(session.submitOption(trackID: 1, now: 2))
        XCTAssertNil(session.submitOption(trackID: 2, now: 2))
        XCTAssertEqual(session.currentRound?.outcome, .correct(elapsed: 1))
    }

    func testAnswerAtDurationBoundaryIsAccepted() {
        var session = makeSession(tracks: [makeTrack(id: 1, title: "One")], duration: 30)
        _ = session.begin(now: 0)
        XCTAssertEqual(session.submitAnswer("One", now: 30), .correct(elapsed: 30))
    }

    func testAnswerAfterDurationTimesOut() {
        var session = makeSession(tracks: [makeTrack(id: 1, title: "One")], duration: 30)
        _ = session.begin(now: 0)
        XCTAssertEqual(session.submitAnswer("One", now: 30.001), .timedOut)
    }

    func testSkipEndsRound() {
        var session = makeSession(tracks: [makeTrack(id: 1, title: "One")])
        _ = session.begin(now: 0)
        XCTAssertEqual(session.skip(), .skipped)
    }

    func testMarkTimedOutAfterDuration() {
        var session = makeSession(tracks: [makeTrack(id: 1, title: "One")], duration: 30)
        _ = session.begin(now: 0)
        XCTAssertNil(session.markTimedOutIfNeeded(now: 30))
        XCTAssertEqual(session.markTimedOutIfNeeded(now: 30.1), .timedOut)
    }

    func testTerminalRoundRejectsFurtherAnswers() {
        var session = makeSession(tracks: [makeTrack(id: 1, title: "One")])
        _ = session.begin(now: 0)
        _ = session.submitAnswer("One", now: 1)
        XCTAssertNil(session.submitAnswer("One", now: 2))
        XCTAssertNil(session.skip())
        XCTAssertEqual(session.currentRound?.outcome, .correct(elapsed: 1))
    }

    func testInterruptEndsRound() {
        var session = makeSession(tracks: [makeTrack(id: 1, title: "One")])
        _ = session.begin(now: 0)
        XCTAssertEqual(session.interrupt(), .interrupted)
        XCTAssertNil(session.submitAnswer("One", now: 1))
    }

    func testAdvanceToNextRoundRestartsClock() {
        var session = makeSession(tracks: [makeTrack(id: 1, title: "One"), makeTrack(id: 2, title: "Two")])
        _ = session.begin(now: 0)
        _ = session.submitAnswer("One", now: 3)
        XCTAssertEqual(session.advance(now: 10), .playing(roundIndex: 1))
        XCTAssertEqual(session.currentRound?.startElapsed, 10)
        XCTAssertEqual(session.currentRound?.track.id, 2)
    }

    func testFinishedAfterFinalRoundProducesSummary() {
        var session = makeSession(tracks: [makeTrack(id: 1, title: "One"), makeTrack(id: 2, title: "Two")])
        _ = session.begin(now: 0)
        _ = session.submitAnswer("One", now: 2)
        _ = session.advance(now: 5)
        _ = session.skip()
        let state = session.advance(now: 6)

        guard case .finished(let result) = state else {
            return XCTFail("Expected finished state")
        }
        XCTAssertEqual(result.correctCount, 1)
        XCTAssertEqual(result.accuracy, 0.5)
        XCTAssertEqual(result.fastestCorrectElapsed, 2)
        XCTAssertNil(session.currentRound)
    }

    func testZeroOutcomeRoundsCountInAccuracy() {
        var session = makeSession(tracks: [makeTrack(id: 1, title: "One"), makeTrack(id: 2, title: "Two")])
        _ = session.begin(now: 0)
        _ = session.skip()
        _ = session.advance(now: 1)
        _ = session.interrupt()
        let state = session.advance(now: 2)
        guard case .finished(let result) = state else {
            return XCTFail("Expected finished state")
        }
        XCTAssertEqual(result.correctCount, 0)
        XCTAssertEqual(result.accuracy, 0)
        XCTAssertNil(result.fastestCorrectElapsed)
    }
}
