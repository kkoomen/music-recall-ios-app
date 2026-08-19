import Foundation

/// Quiz difficulty mode. Easy presents five multiple-choice options per
/// round; expert is identical but plays only a 1-second sample on demand
/// instead of auto-playing the song; hard keeps the free-text answer
/// field.
enum QuizMode: String, Equatable, Sendable {
    case easy
    case expert
    case hard
}
