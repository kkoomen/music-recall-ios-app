import SwiftUI

/// Easy-mode multiple-choice row: title in white larger text, artist in
/// grey smaller text underneath, matching the autocomplete row style.
///
/// Once the round settles, the correct option is highlighted in
/// `success` with a checkmark and the player's wrong pick (when the
/// round was wrong) in `danger` with a cross; every other row dims.
struct OptionRow: View {
    let track: Track
    /// True when this row is the correct answer and the round has ended.
    let isHighlightedCorrect: Bool
    /// True when this row is the player's wrong pick this round.
    let isHighlightedWrong: Bool
    /// False once the round settles; picks are then ignored.
    let isEnabled: Bool

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text(track.title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(titleColor)
                    .lineLimit(1)

                Text(track.artist)
                    .font(.subheadline)
                    .foregroundStyle(artistColor)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            if let icon = trailingIcon {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundStyle(trailingIconColor)
            }
        }
        .frame(maxWidth: .infinity, minHeight: AppTheme.minimumTouchHeight)
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.vertical, AppTheme.Spacing.xs)
        .opacity(isDimmed ? 0.55 : 1)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius)
                .stroke(borderColor, lineWidth: borderWidth)
        }
        .contentShape(Rectangle())
    }

    /// Settled rows that are neither the correct answer nor the player's
    /// wrong pick fall back to the muted look.
    private var isDimmed: Bool {
        !isEnabled && !isHighlightedCorrect && !isHighlightedWrong
    }

    private var titleColor: Color {
        if isHighlightedCorrect { return AppTheme.success }
        if isHighlightedWrong { return AppTheme.danger }
        return AppTheme.primaryText
    }

    private var artistColor: Color {
        if isHighlightedCorrect || isHighlightedWrong { return titleColor }
        return AppTheme.secondaryText
    }

    private var borderColor: Color {
        if isHighlightedCorrect { return AppTheme.success }
        if isHighlightedWrong { return AppTheme.danger }
        return AppTheme.surfaceBorder
    }

    private var borderWidth: CGFloat {
        isHighlightedCorrect || isHighlightedWrong ? 2 : 1
    }

    private var trailingIcon: String? {
        if isHighlightedCorrect { return "checkmark.circle.fill" }
        if isHighlightedWrong { return "xmark.circle.fill" }
        return nil
    }

    private var trailingIconColor: Color {
        isHighlightedCorrect ? AppTheme.success : AppTheme.danger
    }
}
