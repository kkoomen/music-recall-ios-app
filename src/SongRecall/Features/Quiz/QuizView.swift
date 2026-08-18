import SwiftUI

/// Active quiz round.
///
/// Layout: input field at the top, action buttons pinned to the bottom,
/// and the space in between reserved for the autocomplete dropdown that
/// expands while typing.
struct QuizView: View {
    @ObservedObject var viewModel: QuizViewModel
    @FocusState private var answerFieldFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var fieldHeight: CGFloat = 0

    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            header
            answerField
            feedbackBanner
            Spacer(minLength: AppTheme.Spacing.md)
            answerReveal
            Spacer(minLength: AppTheme.Spacing.md)
            actionButtons
        }
        .padding(AppTheme.Spacing.xl)
        .onAppear {
            viewModel.start()
            // Auto-focus the answer field when the quiz starts.
            answerFieldFocused = true
        }
        .onChange(of: viewModel.feedback) { _, newFeedback in
            // Dismiss the keyboard once a round settles so the answer
            // reveal and bottom action buttons are visible.
            if newFeedback != .none {
                answerFieldFocused = false
            }
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
    }

    private var timerColor: Color {
        guard viewModel.roundIsActive else { return AppTheme.secondaryText }
        return viewModel.remainingSeconds <= 5 ? AppTheme.danger : AppTheme.primaryText
    }

    // MARK: - Answer input with attached autocomplete overlay

    private var answerField: some View {
        TextField("Song title or artist — title", text: $viewModel.guess)
            .textFieldStyle(.plain)
            .font(.title3)
            .padding(AppTheme.Spacing.lg)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius))
            .foregroundStyle(AppTheme.primaryText)
            .submitLabel(.go)
            .focused($answerFieldFocused)
            .onSubmit {
                viewModel.submitFromKeyboard()
            }
            .disabled(!viewModel.roundIsActive)
            .onChange(of: viewModel.guess) {
                viewModel.guessDidChange()
            }
            .accessibilityIdentifier(AccessibilityID.quizAnswerField)
            .accessibilityHint("Type the song title, or artist and title")
            .onGeometryChange(for: CGFloat.self, of: { $0.size.height }) { height in
                fieldHeight = height
            }
            .overlay(alignment: .top) {
                if !viewModel.suggestions.isEmpty {
                    suggestionList
                        .offset(y: fieldHeight + AppTheme.Spacing.sm)
                        .transition(.opacity)
                        .animation(.easeOut(duration: 0.15), value: viewModel.suggestions.isEmpty)
                }
            }
            .zIndex(1)
    }

    private var suggestionList: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.suggestions, id: \.track.id) { suggestion in
                Button {
                    viewModel.select(suggestion)
                } label: {
                    SuggestionRow(suggestion: suggestion)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(AccessibilityID.quizSuggestion)
                .accessibilityLabel("\(suggestion.track.title), \(suggestion.track.artist)")

                if suggestion.track.id != viewModel.suggestions.last?.track.id {
                    Divider()
                        .overlay(AppTheme.surfaceBorder)
                }
            }
        }
        .panel(cornerRadius: AppTheme.smallCornerRadius)
        .shadow(color: .black.opacity(0.45), radius: 16, y: 8)
    }

    // MARK: - Answer reveal

    /// Shows the correct answer in the middle of the screen when the
    /// round ended without a correct guess, using the same title/artist
    /// row styling as the autocomplete.
    @ViewBuilder
    private var answerReveal: some View {
        if shouldRevealAnswer, let track = viewModel.currentTrack {
            VStack(spacing: AppTheme.Spacing.xs) {
                Text("The song was")
                    .font(.footnote)
                    .foregroundStyle(AppTheme.secondaryText)
                SuggestionRow(suggestion: TrackSuggestion(track: track))
                    .frame(maxWidth: .infinity)
            }
            .padding(AppTheme.Spacing.md)
            .panel(cornerRadius: AppTheme.cardCornerRadius)
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier(AccessibilityID.quizReveal)
            .accessibilityLabel("The song was \(track.title), \(track.artist)")
            .transition(reduceMotion ? .opacity : .scale(scale: 0.97).combined(with: .opacity))
        }
    }

    private var shouldRevealAnswer: Bool {
        switch viewModel.feedback {
        case .none, .correct:
            return false
        case .wrong, .skipped, .timedOut, .interrupted:
            return true
        }
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
