import XCTest

/// Proves the UI-test target launches the app on the simulator with the
/// stub library.
final class LaunchTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunchShowsHome() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-library", "ready"]
        app.launch()
        XCTAssertTrue(app.buttons["home.startQuiz"].waitForExistence(timeout: 10))
    }
}
