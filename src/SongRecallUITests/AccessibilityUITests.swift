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

        let startButton = app.buttons["home.startHard"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 5))
        startButton.tap()

        // The answer field auto-focuses when the quiz starts.
        let field = app.textFields["quiz.answerField"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5),
                      "Input must auto-focus and show the keyboard at quiz start")

        // Settle the round via the return key; the keyboard dismisses and
        // the bottom action button becomes usable.
        field.typeText("zzz\n")

        let next = app.buttons["quiz.next"]
        XCTAssertTrue(next.waitForExistence(timeout: 5))
        XCTAssertTrue(next.isHittable, "Next button must stay hittable at large Dynamic Type")

        let window = app.windows.firstMatch
        XCTAssertTrue(window.frame.contains(next.frame), "Next button must stay inside the window")

        let timer = app.staticTexts["quiz.timer"]
        XCTAssertTrue(timer.exists && timer.isHittable, "Timer must stay visible at large Dynamic Type")
    }
}
