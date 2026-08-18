import Foundation

/// Weighted scoring for correct recall.
///
/// Formula: `max(100, 1000 - floor(elapsedSeconds) * 30)`
///
/// - Immediate answer: 1,000.
/// - Answer at 30 seconds: 100.
/// - Any non-correct outcome: 0.
enum ScoreCalculator {
    static let maxScore = 1_000
    static let minScore = 100

    static func score(forCorrectAnswerAt elapsed: TimeInterval) -> Int {
        let seconds = floor(max(0, elapsed))
        return max(minScore, maxScore - Int(seconds) * 30)
    }

    static func score(for outcome: RoundOutcome) -> Int {
        switch outcome {
        case .correct(let elapsed):
            return score(forCorrectAnswerAt: elapsed)
        case .wrong, .skipped, .timedOut, .interrupted:
            return 0
        }
    }
}
