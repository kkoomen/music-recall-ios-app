import SwiftUI

/// Active quiz round: artwork, timer, score, answer field, and
/// round feedback.
struct QuizView: View {
    @ObservedObject var viewModel: QuizViewModel
    @FocusState private var answerFieldFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var artworkAccent: Color?

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            header
            artwork
            feedbackBanner
            answerSection
            actionButtons
        }
        .padding(AppTheme.Spacing.xl)
        .onAppear {
            viewModel.start()
        }
        .onChange(of: viewModel.artworkImage) { _, image in
            guard let data = image?.pngData() else {
                artworkAccent = nil
                return
            }
            artworkAccent = ArtworkAccent.color(from: data)
        }
    }

    // MARK: - Header

    private var header: some View {
        ViewThatFits(in: .horizontal) {
            horizontalHeader
            verticalHeader
        }
    }

    private var horizontalHeader: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text("Round \(viewModel.roundNumber) / \(viewModel.totalRounds)")
                    .font(.headline)
                    .foregroundStyle(AppTheme.secondaryText)
                    .accessibilityIdentifier(AccessibilityID.quizRound)
                    .accessibilityLabel("Round \(viewModel.roundNumber) of \(viewModel.totalRounds)")
                Text("Score \(viewModel.score)")
                    .font(.title2.weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(AppTheme.primaryText)
                    .accessibilityIdentifier(AccessibilityID.quizScore)
                    .accessibilityLabel("Score \(viewModel.score)")
            }
            Spacer(minLength: AppTheme.Spacing.lg)
            timerLabel
        }
    }

    private var verticalHeader: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Round \(viewModel.roundNumber) / \(viewModel.totalRounds)")
                .font(.headline)
                .foregroundStyle(AppTheme.secondaryText)
                .accessibilityIdentifier(AccessibilityID.quizRound)
                .accessibilityLabel("Round \(viewModel.roundNumber) of \(viewModel.totalRounds)")
            HStack {
                Text("Score \(viewModel.score)")
                    .font(.title2.weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(AppTheme.primaryText)
                    .accessibilityIdentifier(AccessibilityID.quizScore)
                    .accessibilityLabel("Score \(viewModel.score)")
                Spacer()
                timerLabel
            }
        }
    }

    private var timerLabel: some View {
        Text("\(max(0, viewModel.remainingSeconds))")
            .font(.system(size: 36, weight: .heavy, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(timerColor)
            .accessibilityIdentifier(AccessibilityID.quizTimer)
            .accessibilityLabel("\(max(0, viewModel.remainingSeconds)) seconds remaining")
            .accessibilityHidden(false)
    }

    private var timerColor: Color {
        guard viewModel.roundIsActive else { return AppTheme.secondaryText }
        return viewModel.remainingSeconds <= 5 ? AppTheme.danger : AppTheme.primaryText
    }

    // MARK: - Artwork

    private var artwork: some View {
        Group {
            if let image = viewModel.artworkImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                    .fill(AppTheme.surfaceElevated)
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
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .stroke(AppTheme.surfaceBorder, lineWidth: 1)
        }
        .background {
            // Artwork-derived accent as decoration only; text never sits on it.
            if let artworkAccent {
                RadialGradient(
                    colors: [artworkAccent.opacity(0.4), .clear],
                    center: .center,
                    startRadius: 20,
                    endRadius: 320
                )
            }
        }
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
            .padding(.vertical, AppTheme.Spacing.md)
            .frame(maxWidth: .infinity)
            .panel(cornerRadius: AppTheme.smallCornerRadius)
            .accessibilityIdentifier(AccessibilityID.quizFeedback)
            .accessibilityLabel(feedbackText)
            .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
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
        VStack(spacing: AppTheme.Spacing.md) {
            if viewModel.roundIsActive {
                TextField("Song title or artist — title", text: $viewModel.guess)
                    .textFieldStyle(.plain)
                    .font(.title3)
                    .padding(AppTheme.Spacing.lg)
                    .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius))
                    .foregroundStyle(AppTheme.primaryText)
                    .submitLabel(.go)
                    .focused($answerFieldFocused)
                    .onSubmit {
                        viewModel.submit()
                    }
                    .accessibilityIdentifier(AccessibilityID.quizAnswerField)
                    .accessibilityHint("Type the song title, or artist and title")
                    .disabled(!viewModel.roundIsActive)
                    .transition(.opacity)
            }
        }
    }

    // MARK: - Actions

    private var actionButtons: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            if viewModel.roundIsActive {
                Button(action: viewModel.skip) {
                    Text("Skip")
                        .font(.title3.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: AppTheme.minimumTouchHeight)
                }
                .buttonStyle(.bordered)
                .tint(AppTheme.secondaryText)
                .controlSize(.large)
                .accessibilityIdentifier(AccessibilityID.quizSkip)

                Button(action: viewModel.submit) {
                    Text("Submit")
                        .font(.title3.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: AppTheme.minimumTouchHeight)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.accent)
                .foregroundStyle(AppTheme.accentText)
                .controlSize(.large)
                .disabled(!viewModel.canSubmit)
                .accessibilityIdentifier(AccessibilityID.quizSubmit)
            } else {
                Button(action: viewModel.advance) {
                    Text("Next")
                        .font(.title3.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: AppTheme.minimumTouchHeight)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.accent)
                .foregroundStyle(AppTheme.accentText)
                .controlSize(.large)
                .accessibilityIdentifier(AccessibilityID.quizNext)
                .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
            }
        }
        .animation(reduceMotion ? nil : AppTheme.standardAnimation, value: viewModel.feedback)
    }
}
