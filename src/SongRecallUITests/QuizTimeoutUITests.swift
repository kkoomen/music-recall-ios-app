import XCTest

/// Timeout behavior end to end, using a 2-second round duration so the
/// test does not wait the real 30 seconds.
final class QuizTimeoutUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testRoundTimesOutWithRecovery() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-library", "ready", "-uitest-round-duration", "2"]
        app.launch()

        let startButton = app.buttons["home.startHard"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 5))
        startButton.tap()

        let timer = app.staticTexts["quiz.timer"]
        XCTAssertTrue(timer.waitForExistence(timeout: 5))

        let feedback = app.staticTexts["quiz.feedback"]
        XCTAssertTrue(feedback.waitForExistence(timeout: 10), "Round must time out")
        XCTAssertTrue(feedback.label.contains("Time's up"), "Got: \(feedback.label)")

        // Recovery: Next advances to round 2.
        let next = app.buttons["quiz.next"]
        XCTAssertTrue(next.waitForExistence(timeout: 5))
        XCTAssertTrue(next.isHittable)
    }
}
