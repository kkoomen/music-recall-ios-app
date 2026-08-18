import Foundation

/// Normalizes free-text guesses for matching: case-insensitive,
/// diacritic-insensitive, punctuation removed, whitespace collapsed.
enum AnswerNormalizer {
    static func normalize(_ input: String) -> String {
        input
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
            .filter { $0.isLetter || $0.isNumber || $0.isWhitespace }
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }
}
