import XCTest

/// Permission screen states against the stub library.
final class PermissionFlowUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testNotDeterminedOffersAllowAccess() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-library", "notDetermined"]
        app.launch()

        let title = app.staticTexts["permission.title"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        XCTAssertEqual(title.label, "Your music stays on your iPhone")
        XCTAssertTrue(app.buttons["permission.allow"].exists)
    }

    func testRestrictedShowsExplanation() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-library", "restricted"]
        app.launch()

        let title = app.staticTexts["permission.title"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        XCTAssertEqual(title.label, "Music access is restricted")
        // No in-app action exists for restricted access.
        XCTAssertFalse(app.buttons["permission.allow"].exists)
    }
}
