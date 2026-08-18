import SwiftUI

@main
struct SongRecallApp: App {
    @StateObject private var appModel = AppModel.makeFromEnvironment()

    var body: some Scene {
        WindowGroup {
            RootView(appModel: appModel)
        }
    }
}
