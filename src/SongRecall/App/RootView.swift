import SwiftUI

/// Root view: routes between library, quiz, and results.
struct RootView: View {
    @ObservedObject var appModel: AppModel

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            switch appModel.route {
            case .library:
                libraryContent
            case .quiz:
                if let viewModel = appModel.quizViewModel {
                    QuizView(viewModel: viewModel)
                        .transition(.opacity)
                }
            case .results(let result):
                ResultsView(
                    result: result,
                    onReplay: { appModel.replay() },
                    onHome: { appModel.backToLibrary() }
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: appModel.route)
        .preferredColorScheme(.dark)
        .task {
            await appModel.loadLibrary()
        }
    }

    @ViewBuilder
    private var libraryContent: some View {
        switch appModel.libraryState {
        case .loading:
            VStack(spacing: 16) {
                ProgressView()
                    .controlSize(.large)
                    .tint(AppTheme.accent)
                Text("Loading your library…")
                    .foregroundStyle(AppTheme.secondaryText)
            }
        case .notDetermined:
            PermissionView(
                state: .notDetermined,
                onRequestAccess: { Task { await appModel.requestAccessAndLoad() } },
                onOpenSettings: { SettingsOpener.open() }
            )
        case .denied:
            PermissionView(
                state: .denied,
                onRequestAccess: { Task { await appModel.requestAccessAndLoad() } },
                onOpenSettings: { SettingsOpener.open() }
            )
        case .restricted:
            PermissionView(
                state: .restricted,
                onRequestAccess: { Task { await appModel.requestAccessAndLoad() } },
                onOpenSettings: { SettingsOpener.open() }
            )
        case .empty:
            PermissionView(
                state: .empty,
                onRequestAccess: { Task { await appModel.requestAccessAndLoad() } },
                onOpenSettings: { SettingsOpener.open() }
            )
        case .ready(let tracks):
            HomeView(
                trackCount: tracks.count,
                onStartQuiz: { appModel.startQuiz() }
            )
        }
    }
}
