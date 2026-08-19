import Foundation

/// Quiz difficulty mode. Easy presents five multiple-choice options per
/// round; hard keeps the free-text answer field.
enum QuizMode: String, Equatable, Sendable {
    case easy
    case hard
}
