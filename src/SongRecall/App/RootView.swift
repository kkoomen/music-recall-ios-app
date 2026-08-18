import SwiftUI

/// Placeholder root view for the app shell. Replaced by the full
/// first-use-to-results flow in a later roadmap feature.
struct RootView: View {
    var body: some View {
        Text("Song Recall")
            .font(.largeTitle)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            .accessibilityIdentifier("root.placeholder")
    }
}
