import Foundation

/// Expert-mode sample playback: one random 1-second part of the song,
/// replayed on demand up to three times per round.
enum SamplePicker {
    /// Length of the expert-mode sample in seconds.
    static let sampleDuration: TimeInterval = 1

    /// Random start offset such that a `sampleDuration`-long sample fits
    /// inside the song. Songs shorter than the sample (or missing a
    /// measurable duration) start at 0. Deterministic per random seed.
    static func offset(
        songDuration: TimeInterval,
        random: RandomSource,
        sampleDuration: TimeInterval = Self.sampleDuration
    ) -> TimeInterval {
        let duration = max(0, songDuration)
        guard duration > sampleDuration else { return 0 }
        return random.nextDouble() * (duration - sampleDuration)
    }
}
