import XCTest

/// Proves the UI-test target can launch the app on the simulator.
final class LaunchTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.staticTexts["root.placeholder"].waitForExistence(timeout: 10))
    }
}
