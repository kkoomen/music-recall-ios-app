import UIKit

/// Restrained haptic feedback for round outcomes. Disabled when the
/// user enables Reduce Motion.
enum Haptics {
    static func success() {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func error() {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    static func lightImpact() {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private static var enabled: Bool {
        !UIAccessibility.isReduceMotionEnabled
    }
}
