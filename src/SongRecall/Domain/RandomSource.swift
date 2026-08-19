import Foundation

/// Injectable randomness used for quiz selection.
protocol RandomSource: Sendable {
    func shuffled<T>(_ elements: [T]) -> [T]
    /// Uniform random value in [0, 1).
    func nextDouble() -> Double
}
