import Foundation

/// Deterministic, seedable shuffle for tests and previews. SplitMix64
/// generator so the same seed always produces the same order.
struct SeededRandomSource: RandomSource, RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    func shuffled<T>(_ elements: [T]) -> [T] {
        var generator = self
        return elements.shuffled(using: &generator)
    }
}
