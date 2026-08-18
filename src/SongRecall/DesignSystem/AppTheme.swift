import SwiftUI

/// Dark album-art arcade design tokens.
///
/// Intentional product decision: the app is dark-only (arcade look),
/// so `.preferredColorScheme(.dark)` is forced and there is no light
/// fallback. Semantic colors below keep text readable against every
/// surface and against artwork-derived decoration.
enum AppTheme {
    // MARK: Surfaces

    static let background = Color(red: 0.055, green: 0.055, blue: 0.09)
    static let surface = Color(red: 0.12, green: 0.12, blue: 0.17)
    static let surfaceElevated = Color(red: 0.17, green: 0.17, blue: 0.23)
    static let surfaceBorder = Color.white.opacity(0.08)

    // MARK: Text

    static let primaryText = Color(red: 0.96, green: 0.96, blue: 0.98)
    static let secondaryText = Color(red: 0.62, green: 0.62, blue: 0.70)

    // MARK: Semantic

    /// Hot arcade accent used for primary actions and highlights.
    static let accent = Color(red: 0.99, green: 0.49, blue: 0.59)
    /// Near-black text on top of `accent` (contrast ≈ 9:1).
    static let accentText = Color(red: 0.08, green: 0.06, blue: 0.07)
    static let success = Color(red: 0.35, green: 0.85, blue: 0.55)
    static let danger = Color(red: 0.96, green: 0.42, blue: 0.42)

    // MARK: Spacing

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    // MARK: Shape

    static let cardCornerRadius: CGFloat = 20
    static let smallCornerRadius: CGFloat = 14
    static let buttonCornerRadius: CGFloat = 16

    // MARK: Motion

    static let standardAnimation = Animation.easeInOut(duration: 0.25)

    /// Minimum touch target height for interactive elements.
    static let minimumTouchHeight: CGFloat = 48
}

/// Rounded panel background shared by cards and banners.
struct PanelModifier: ViewModifier {
    var cornerRadius: CGFloat = AppTheme.cardCornerRadius

    func body(content: Content) -> some View {
        content
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(AppTheme.surfaceBorder, lineWidth: 1)
            }
    }
}

extension View {
    /// Applies the standard arcade panel surface.
    func panel(cornerRadius: CGFloat = AppTheme.cardCornerRadius) -> some View {
        modifier(PanelModifier(cornerRadius: cornerRadius))
    }
}
