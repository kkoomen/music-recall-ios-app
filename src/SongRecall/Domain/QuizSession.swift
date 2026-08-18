import Foundation

/// Pure quiz state machine. All time comes from explicit `now`
/// parameters so tests stay fully deterministic. No system frameworks.
struct QuizSession: Equatable, Sendable {
    let configuration: QuizConfiguration
    private(set) var rounds: [QuizRound]
    private(set) var state: QuizState = .notStarted

    init(configuration: QuizConfiguration, rounds: [QuizRound]) {
        self.configuration = configuration
        self.rounds = rounds
    }

    var currentRound: QuizRound? {
        guard case .playing(let index) = state, rounds.indices.contains(index) else {
            return nil
        }
        return rounds[index]
    }

    /// Starts the first round. No-op unless not started.
    @discardableResult
    mutating func begin(now: TimeInterval) -> QuizState {
        guard state == .notStarted, !rounds.isEmpty else { return state }
        rounds[0].start(at: now)
        state = .playing(roundIndex: 0)
        return state
    }

    /// Accepts one normalized answer for the active round. Returns nil
    /// (and changes nothing) when no round is active. An answer at or
    /// before the duration boundary is evaluated; later answers time out.
    @discardableResult
    mutating func submitAnswer(_ guess: String, now: TimeInterval) -> RoundOutcome? {
        guard case .playing(let index) = state,
              rounds.indices.contains(index),
              rounds[index].isActive,
              let startElapsed = rounds[index].startElapsed
        else { return nil }

        let elapsed = max(0, now - startElapsed)
        let outcome: RoundOutcome
        if elapsed > configuration.roundDuration {
            outcome = .timedOut
        } else if AnswerMatcher.isMatch(guess: guess, track: rounds[index].track) {
            outcome = .correct(elapsed: elapsed)
        } else {
            outcome = .wrong
        }
        rounds[index].end(with: outcome)
        return outcome
    }

    /// Ends the active round as skipped. Returns nil when no round is active.
    @discardableResult
    mutating func skip() -> RoundOutcome? {
        guard case .playing(let index) = state,
              rounds.indices.contains(index),
              rounds[index].isActive
        else { return nil }
        let outcome = RoundOutcome.skipped
        rounds[index].end(with: outcome)
        return outcome
    }

    /// Ends the active round as timed out when the duration passed.
    @discardableResult
    mutating func markTimedOutIfNeeded(now: TimeInterval) -> RoundOutcome? {
        guard case .playing(let index) = state,
              rounds.indices.contains(index),
              rounds[index].isActive,
              let startElapsed = rounds[index].startElapsed,
              now - startElapsed > configuration.roundDuration
        else { return nil }
        let outcome = RoundOutcome.timedOut
        rounds[index].end(with: outcome)
        return outcome
    }

    /// Ends the active round as interrupted (playback failure or system
    /// interruption). The UI shows a recovery message and lets the user
    /// continue.
    @discardableResult
    mutating func interrupt() -> RoundOutcome? {
        guard case .playing(let index) = state,
              rounds.indices.contains(index),
              rounds[index].isActive
        else { return nil }
        let outcome = RoundOutcome.interrupted
        rounds[index].end(with: outcome)
        return outcome
    }

    /// Advances to the next round, or finishes the session after the
    /// final round. Selection already guarantees no duplicates.
    @discardableResult
    mutating func advance(now: TimeInterval) -> QuizState {
        guard case .playing(let index) = state else { return state }
        if index + 1 < rounds.count {
            rounds[index + 1].start(at: now)
            state = .playing(roundIndex: index + 1)
        } else {
            state = .finished(QuizResult(rounds: rounds))
        }
        return state
    }
}
