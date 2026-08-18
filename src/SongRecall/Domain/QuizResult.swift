import Foundation

/// Final session summary. Scoring is layered on by the score calculator.
struct QuizResult: Equatable, Sendable {
    let rounds: [QuizRound]

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
}
