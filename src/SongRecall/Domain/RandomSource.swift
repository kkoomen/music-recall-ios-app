import Foundation

/// Injectable randomness used for quiz selection.
protocol RandomSource: Sendable {
    func shuffled<T>(_ elements: [T]) -> [T]
}
