import Foundation

/// Scoring: 10 base points plus one point per full remaining second
/// (matching the displayed countdown), doubled when the answer lands
/// within the first five seconds. Wrong answers deduct 5, skips deduct
/// 10; the cumulative score never goes below 0. Timeout and playback
/// interruption score 0.
enum ScoreCalculator {
    /// Base points for any correct answer.
    static let basePoints = 10
    /// Answers before this many seconds of round start earn 2x.
    static let fastThreshold: TimeInterval = 5
    /// Points deducted for a wrong answer.
    static let wrongPenalty = 5
    /// Points deducted when the player skips.
    static let skipPenalty = 10

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

    /// Per-round score contribution. May be negative for wrong answers
    /// and skips; the session score clamps the running total at 0.
    static func score(
        for outcome: RoundOutcome,
        roundDuration: TimeInterval = 30
    ) -> Int {
        switch outcome {
        case .correct(let elapsed):
            return score(forCorrectAnswerAt: elapsed, roundDuration: roundDuration)
        case .wrong:
            return -wrongPenalty
        case .skipped:
            return -skipPenalty
        case .timedOut, .interrupted:
            return 0
        }
    }
}
