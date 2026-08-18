import Foundation

/// Non-seeded production randomness using Swift's default RNG.
struct SystemRandomSource: RandomSource {
    func shuffled<T>(_ elements: [T]) -> [T] {
        elements.shuffled()
    }
}
