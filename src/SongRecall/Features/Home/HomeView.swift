import SwiftUI

/// Home screen: local track count and the single Start Quiz action.
struct HomeView: View {
    let trackCount: Int
    let onStartQuiz: () -> Void

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

            Button(action: onStartQuiz) {
                Label("Start Quiz", systemImage: "play.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AppTheme.accentText)
                    .frame(maxWidth: .infinity, minHeight: AppTheme.minimumTouchHeight)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accent)
            .controlSize(.large)
            .accessibilityIdentifier(AccessibilityID.homeStartQuiz)

            Text("\(trackCount == 1 ? "1 song" : "\(trackCount) songs") · 30s per round · \(min(trackCount, 10)) rounds")
                .font(.footnote)
                .foregroundStyle(AppTheme.secondaryText)
        }
        .padding(24)
    }
}

#Preview {
    HomeView(trackCount: 42, onStartQuiz: {})
        .background(AppTheme.background)
        .preferredColorScheme(.dark)
}
