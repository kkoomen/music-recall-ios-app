import Foundation

/// Scoring: 10 base points plus one point per full remaining second
/// (matching the displayed countdown), doubled when the answer lands
/// within the first five seconds. Wrong, skip, timeout, and interruption
/// score 0.
enum ScoreCalculator {
    /// Base points for any correct answer.
    static let basePoints = 10
    /// Answers before this many seconds of round start earn 2x.
    static let fastThreshold: TimeInterval = 5

    /// Result of scoring a correct answer.
    struct Breakdown: Equatable, Sendable {
        /// Final points including the multiplier.
        let points: Int
        /// True when the answer landed within the fast threshold (2x).
        let isFast: Bool
    }

    static func breakdown(
        forCorrectAnswerAt elapsed: TimeInterval,
        roundDuration: TimeInterval = 30
    ) -> Breakdown {
        let clampedElapsed = max(0, elapsed)
        let remaining = max(0, Int(ceil(roundDuration - clampedElapsed)))
        let isFast = clampedElapsed < fastThreshold
        let points = (basePoints + remaining) * (isFast ? 2 : 1)
        return Breakdown(points: points, isFast: isFast)
    }

    static func score(
        forCorrectAnswerAt elapsed: TimeInterval,
        roundDuration: TimeInterval = 30
    ) -> Int {
        breakdown(forCorrectAnswerAt: elapsed, roundDuration: roundDuration).points
    }

    static func score(
        for outcome: RoundOutcome,
        roundDuration: TimeInterval = 30
    ) -> Int {
        switch outcome {
        case .correct(let elapsed):
            return score(forCorrectAnswerAt: elapsed, roundDuration: roundDuration)
        case .wrong, .skipped, .timedOut, .interrupted:
            return 0
        }
    }
}
