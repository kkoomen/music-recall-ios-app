import SwiftUI

/// Home screen: local track count and the two quiz mode actions.
struct HomeView: View {
    let trackCount: Int
    let onStartEasy: () -> Void
    let onStartHard: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: "music.note.list")
                .font(.system(size: 64))
                .foregroundStyle(AppTheme.accent)

            Text("Song Recall")
                .font(.system(size: 40, weight: .heavy, design: .rounded))
                .foregroundStyle(AppTheme.primaryText)

            Text(trackCount == 1 ? "1 song ready" : "\(trackCount) songs ready")
                .font(.title3)
                .foregroundStyle(AppTheme.secondaryText)
                .accessibilityIdentifier(AccessibilityID.homeTrackCount)

            Spacer()

            VStack(spacing: AppTheme.Spacing.md) {
                Button(action: onStartEasy) {
                    modeLabel(title: "Easy Mode", caption: "5 choices")
                        .foregroundStyle(AppTheme.accentText)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.accent)
                .controlSize(.large)
                .accessibilityIdentifier(AccessibilityID.homeStartEasy)

                Button(action: onStartHard) {
                    modeLabel(title: "Hard Mode", caption: "Type the answer")
                        .foregroundStyle(AppTheme.primaryText)
                }
                .buttonStyle(.bordered)
                .tint(AppTheme.secondaryText)
                .controlSize(.large)
                .accessibilityIdentifier(AccessibilityID.homeStartHard)
            }

            Text("\(trackCount == 1 ? "1 song" : "\(trackCount) songs") · 30s per round · \(min(trackCount, 10)) rounds")
                .font(.footnote)
                .foregroundStyle(AppTheme.secondaryText)
        }
        .padding(24)
    }

    private func modeLabel(title: String, caption: String) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.title3.weight(.semibold))
            Text(caption)
                .font(.footnote)
                .opacity(0.85)
        }
        .frame(maxWidth: .infinity, minHeight: AppTheme.minimumTouchHeight)
    }
}

#Preview {
    HomeView(trackCount: 42, onStartEasy: {}, onStartHard: {})
        .background(AppTheme.background)
        .preferredColorScheme(.dark)
}
