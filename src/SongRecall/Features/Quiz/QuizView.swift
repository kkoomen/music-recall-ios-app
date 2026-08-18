import SwiftUI

/// Active quiz round: artwork, timer, score, answer field, and
/// round feedback.
struct QuizView: View {
    @ObservedObject var viewModel: QuizViewModel
    @FocusState private var answerFieldFocused: Bool

    var body: some View {
        VStack(spacing: 24) {
            header
            artwork
            feedbackBanner
            answerSection
            actionButtons
        }
        .padding(24)
        .onAppear {
            viewModel.start()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Round \(viewModel.roundNumber) / \(viewModel.totalRounds)")
                    .font(.headline)
                    .foregroundStyle(AppTheme.secondaryText)
                    .accessibilityIdentifier(AccessibilityID.quizRound)
                Text("Score \(viewModel.score)")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(AppTheme.primaryText)
                    .accessibilityIdentifier(AccessibilityID.quizScore)
            }
            Spacer()
            Text(timeString)
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(timerColor)
                .accessibilityIdentifier(AccessibilityID.quizTimer)
        }
    }

    private var timeString: String {
        "\(max(0, viewModel.remainingSeconds))"
    }

    private var timerColor: Color {
        guard viewModel.roundIsActive else { return AppTheme.secondaryText }
        return viewModel.remainingSeconds <= 5 ? AppTheme.danger : AppTheme.primaryText
    }

    // MARK: - Artwork

    private var artwork: some View {
        Group {
            if let data = viewModel.artworkData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                    .fill(AppTheme.surface)
                    .overlay {
                        Image(systemName: "music.note")
                            .font(.system(size: 56))
                            .foregroundStyle(AppTheme.secondaryText)
                    }
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
        .accessibilityIdentifier(AccessibilityID.quizArtwork)
        .accessibilityLabel("Song artwork")
    }

    // MARK: - Feedback

    @ViewBuilder
    private var feedbackBanner: some View {
        if viewModel.feedback != .none {
            HStack(spacing: 10) {
                Image(systemName: feedbackIcon)
                    .font(.headline)
                Text(feedbackText)
                    .font(.headline)
                    .multilineTextAlignment(.center)
            }
            .foregroundStyle(feedbackColor)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 14))
            .accessibilityIdentifier(AccessibilityID.quizFeedback)
            .accessibilityLabel(feedbackText)
        }
    }

    private var feedbackText: String {
        switch viewModel.feedback {
        case .none: return ""
        case .correct(let score): return "Correct! +\(score)"
        case .wrong: return "Not this time"
        case .skipped: return "Skipped"
        case .timedOut: return "Time's up"
        case .interrupted: return "Playback was interrupted"
        }
    }

    private var feedbackIcon: String {
        switch viewModel.feedback {
        case .correct: return "checkmark.circle.fill"
        case .wrong, .timedOut: return "xmark.circle.fill"
        case .skipped: return "forward.fill"
        case .interrupted: return "exclamationmark.triangle.fill"
        case .none: return ""
        }
    }

    private var feedbackColor: Color {
        switch viewModel.feedback {
        case .correct: return AppTheme.success
        case .wrong, .timedOut: return AppTheme.danger
        case .skipped: return AppTheme.secondaryText
        case .interrupted: return AppTheme.danger
        case .none: return .clear
        }
    }

    // MARK: - Answer

    private var answerSection: some View {
        VStack(spacing: 12) {
            if viewModel.roundIsActive {
                TextField("Song title or artist — title", text: $viewModel.guess)
                    .textFieldStyle(.plain)
                    .font(.title3)
                    .padding(14)
                    .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(AppTheme.primaryText)
                    .submitLabel(.go)
                    .focused($answerFieldFocused)
                    .onSubmit {
                        viewModel.submit()
                    }
                    .accessibilityIdentifier(AccessibilityID.quizAnswerField)
                    .disabled(!viewModel.roundIsActive)
            }
        }
    }

    // MARK: - Actions

    private var actionButtons: some View {
        HStack(spacing: 12) {
            if viewModel.roundIsActive {
                Button(action: viewModel.skip) {
                    Text("Skip")
                        .font(.title3.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.bordered)
                .tint(AppTheme.secondaryText)
                .controlSize(.large)
                .accessibilityIdentifier(AccessibilityID.quizSkip)

                Button(action: viewModel.submit) {
                    Text("Submit")
                        .font(.title3.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.accent)
                .controlSize(.large)
                .disabled(!viewModel.canSubmit)
                .accessibilityIdentifier(AccessibilityID.quizSubmit)
            } else {
                Button(action: viewModel.advance) {
                    Text("Next")
                        .font(.title3.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.accent)
                .controlSize(.large)
                .accessibilityIdentifier(AccessibilityID.quizNext)
            }
        }
    }
}
