import Foundation

/// Final session summary. Scoring is layered on by the score calculator.
struct QuizResult: Equatable, Sendable {
    let rounds: [QuizRound]
    let roundDuration: TimeInterval

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

    /// Sum of per-round scores from the weighted score calculator.
    var totalScore: Int {
        rounds.compactMap(\.outcome).reduce(0) {
            $0 + ScoreCalculator.score(for: $1, roundDuration: roundDuration)
        }
    }
}
