import SwiftUI

/// Session summary: total score, correct count, accuracy, fastest
/// answer, and replay.
struct ResultsView: View {
    let result: QuizResult
    let onReplay: () -> Void
    let onHome: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "trophy.fill")
                .font(.system(size: 56))
                .foregroundStyle(AppTheme.accent)

            Text("Quiz Complete")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.primaryText)

            Text("\(result.totalScore)")
                .font(.system(size: 72, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(AppTheme.primaryText)
                .accessibilityIdentifier(AccessibilityID.resultsScore)
                .accessibilityLabel("Total score \(result.totalScore)")

            statGrid

            Spacer()

            Button(action: onReplay) {
                Label("Play Again", systemImage: "arrow.clockwise")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AppTheme.accentText)
                    .frame(maxWidth: .infinity, minHeight: AppTheme.minimumTouchHeight)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accent)
            .controlSize(.large)
            .accessibilityIdentifier(AccessibilityID.resultsReplay)

            Button(action: onHome) {
                Text("Back to Library")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: AppTheme.minimumTouchHeight)
            }
            .buttonStyle(.bordered)
            .tint(AppTheme.secondaryText)
            .controlSize(.large)
            .accessibilityIdentifier(AccessibilityID.resultsHome)
        }
        .padding(24)
    }

    private var statGrid: some View {
        HStack(spacing: 12) {
            statCell(
                title: "Correct",
                value: "\(result.correctCount)",
                id: AccessibilityID.resultsCorrect
            )
            statCell(
                title: "Accuracy",
                value: "\(Int((result.accuracy * 100).rounded()))%",
                id: AccessibilityID.resultsAccuracy
            )
            statCell(
                title: "Fastest",
                value: fastestString,
                id: AccessibilityID.resultsFastest
            )
            statCell(
                title: "2x Multipliers",
                value: "\(result.fastCount)",
                id: AccessibilityID.resultsMultipliers,
                caption: "2x",
                icon: "bolt.fill"
            )
        }
    }

    private var fastestString: String {
        guard let fastest = result.fastestCorrectElapsed else { return "—" }
        return String(format: "%.1fs", fastest)
    }

    private func statCell(
        title: String,
        value: String,
        id: String,
        caption: String? = nil,
        icon: String? = nil
    ) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.title2.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(AppTheme.primaryText)

            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(caption ?? title)
                    .font(.caption)
            }
            .foregroundStyle(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(id)
        .accessibilityLabel("\(title): \(value)")
    }
}
