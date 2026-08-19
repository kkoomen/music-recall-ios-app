import Foundation

/// Builds the multiple-choice options for one easy-mode round.
///
/// Pure and deterministic: the correct track is always included, decoys
/// are drawn from the catalog via the injected random source, and the
/// final list is shuffled so the correct answer's position is never
/// predictable. Decoys whose normalized title equals the correct
/// track's title — or duplicates another decoy's title — are excluded,
/// so the player never sees two identically labeled options.
enum OptionGenerator {
    /// Number of options shown per round.
    static let optionLimit = 5

    /// Returns up to `limit` options (fewer when the catalog is small,
    /// never fewer than one: the correct track itself).
    static func options(
        for track: Track,
        from catalog: [Track],
        random: RandomSource,
        limit: Int = optionLimit
    ) -> [Track] {
        guard limit > 1 else { return [track] }

        let correctTitle = AnswerNormalizer.normalize(track.title)
        var seenTitles: Set<String> = [correctTitle]
        let decoys = catalog.filter { candidate in
            guard candidate.id != track.id else { return false }
            let title = AnswerNormalizer.normalize(candidate.title)
            return seenTitles.insert(title).inserted
        }

        let picked = Array(random.shuffled(decoys).prefix(limit - 1))
        return random.shuffled(picked + [track])
    }
}
