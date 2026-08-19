import Foundation

/// Final session summary. Scoring is layered on by the score calculator.
struct QuizResult: Equatable, Sendable {
    let rounds: [QuizRound]
    let roundDuration: TimeInterval
    /// Fast-answer threshold used for the 2x multiplier (3s easy, 5s
    /// hard), carried so totals match the mode that produced them.
    let fastThreshold: TimeInterval

    init(
        rounds: [QuizRound],
        roundDuration: TimeInterval,
        fastThreshold: TimeInterval = ScoreCalculator.fastThreshold
    ) {
        self.rounds = rounds
        self.roundDuration = roundDuration
        self.fastThreshold = fastThreshold
    }

    var correctCount: Int {
        rounds.filter(\.isCorrect).count
    }

    var accuracy: Double {
        guard !rounds.isEmpty else { return 0 }
        return Double(correctCount) / Double(rounds.count)
    }

    var fastestCorrectElapsed: TimeInterval? {
        rounds.compactMap(\.elapsedForScoring).min()
    }

    /// Number of correct answers that landed within the fast window and
    /// earned the 2x multiplier, using this result's mode threshold.
    var fastCount: Int {
        rounds.reduce(0) { count, round in
            guard case .correct(let elapsed) = round.outcome else { return count }
            let breakdown = ScoreCalculator.breakdown(
                forCorrectAnswerAt: elapsed,
                roundDuration: roundDuration,
                fastThreshold: fastThreshold
            )
            return count + (breakdown.isFast ? 1 : 0)
        }
    }

    /// Sum of per-round scores, clamped so the total never goes below 0.
    var totalScore: Int {
        let sum = rounds.compactMap(\.outcome).reduce(0) {
            $0 + ScoreCalculator.score(
                for: $1,
                roundDuration: roundDuration,
                fastThreshold: fastThreshold
            )
        }
        return max(0, sum)
    }
}
