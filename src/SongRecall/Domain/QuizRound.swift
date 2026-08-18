import Foundation

/// One quiz round. Becomes terminal exactly once; later events are
/// rejected.
struct QuizRound: Equatable, Sendable {
    let track: Track
    /// Monotonic elapsed seconds at round start, set when the round
    /// begins (nil until then).
    private(set) var startElapsed: TimeInterval?
    private(set) var outcome: RoundOutcome?

    var isActive: Bool { outcome == nil }
    var isCorrect: Bool {
        if case .correct = outcome { return true }
        return false
    }
    /// Elapsed seconds of the correct answer, when the round was correct.
    var elapsedForScoring: TimeInterval? {
        if case .correct(let elapsed) = outcome { return elapsed }
        return nil
    }

    mutating func start(at elapsed: TimeInterval) {
        guard startElapsed == nil else { return }
        startElapsed = elapsed
    }

    /// First terminal event wins; later calls are ignored.
    mutating func end(with newOutcome: RoundOutcome) {
        guard outcome == nil else { return }
        outcome = newOutcome
    }
}
