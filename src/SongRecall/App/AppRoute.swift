import Foundation

/// App-wide navigation routes.
enum AppRoute: Equatable {
    case library
    case quiz
    case results(QuizResult)
}
