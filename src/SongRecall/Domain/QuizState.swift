import Foundation

/// High-level quiz state. Terminal states reject answer events.
enum QuizState: Equatable, Sendable {
    case notStarted
    case playing(roundIndex: Int)
    case finished(QuizResult)
}
