import XCTest

/// Accessibility-focused UI checks: the quiz stays usable at the
/// largest Dynamic Type sizes without clipping.
final class AccessibilityUITests: XCTestCase {
    func testQuizUsableAtAccessibilityXXLType() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-library", "ready"]
        // Largest supported Dynamic Type size.
        app.launchEnvironment["UIPreferredContentSizeCategoryName"] = "UICTContentSizeCategoryAccessibilityXXXL"
        app.launch()

        let startButton = app.buttons["home.startQuiz"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 5))
        startButton.tap()

        let submit = app.buttons["quiz.submit"]
        XCTAssertTrue(submit.waitForExistence(timeout: 5))
        XCTAssertTrue(submit.isHittable, "Submit button must stay hittable at large Dynamic Type")

        let window = app.windows.firstMatch
        XCTAssertTrue(window.frame.contains(submit.frame), "Submit button must stay inside the window")

        let timer = app.staticTexts["quiz.timer"]
        XCTAssertTrue(timer.exists && timer.isHittable, "Timer must stay visible at large Dynamic Type")
    }
}
