import SwiftUI

/// Autocomplete row: title in white larger text, artist in grey
/// smaller text underneath.
struct SuggestionRow: View {
    let suggestion: TrackSuggestion

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(suggestion.track.title)
                .font(.body.weight(.semibold))
                .foregroundStyle(AppTheme.primaryText)
                .lineLimit(1)

            Text(suggestion.track.artist)
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryText)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.vertical, AppTheme.Spacing.sm)
        .contentShape(Rectangle())
    }
}
