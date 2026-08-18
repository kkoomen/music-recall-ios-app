import Foundation

/// Accepts an exact normalized title or an exact normalized
/// artist-title form. No fuzzy matching in the MVP.
enum AnswerMatcher {
    static func isMatch(guess: String, track: Track) -> Bool {
        let normalized = AnswerNormalizer.normalize(guess)
        guard !normalized.isEmpty else { return false }
        let title = AnswerNormalizer.normalize(track.title)
        let artistTitle = AnswerNormalizer.normalize("\(track.artist) \(track.title)")
        return normalized == title || normalized == artistTitle
    }
}
