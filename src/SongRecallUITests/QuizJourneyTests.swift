import XCTest

/// End-to-end journey against the stub library (`-uitest-library ready`,
/// seed 0 selection order: Gamma Song, Beta Song, Alpha Song).
///
/// While the keyboard is up the bottom action buttons are covered, so
/// answers are submitted with the return key (`\n`), matching the
/// primary in-quiz interaction.
final class QuizJourneyTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uitest-library", "ready"]
    }

    func testFullJourneyToResultsAndReplay() throws {
        app.launch()

        // Home: track count and start button.
        let startButton = app.buttons[AccessibilityID.homeStartQuiz]
        XCTAssertTrue(startButton.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts[AccessibilityID.homeTrackCount].exists)

        startButton.tap()

        // Round 1: correct answer for Gamma Song via return key.
        assertRound(number: 1, of: 3)
        answer("Gamma Song")
        // Answered within 5 seconds: the fast celebration shows.
        assertFeedback(contains: "2x multiplier")
        // A correct guess does not reveal the answer.
        XCTAssertFalse(revealElement.exists, "Correct answers must not show the reveal")
        app.buttons[AccessibilityID.quizNext].tap()

        // Round 2: wrong answer for Beta Song via return key.
        assertRound(number: 2, of: 3)
        answer("Not A Real Title")
        assertFeedback(contains: "Not this time")
        // The correct answer is revealed in the middle: title + artist.
        XCTAssertTrue(revealElement.waitForExistence(timeout: 5))
        XCTAssertEqual(revealElement.label, "The song was Beta Song, Artist Two")
        app.buttons[AccessibilityID.quizNext].tap()

        // Round 3: skip for Alpha Song (keyboard is down).
        assertRound(number: 3, of: 3)
        app.buttons[AccessibilityID.quizSkip].tap()
        assertFeedback(contains: "Skipped")
        app.buttons[AccessibilityID.quizNext].tap()

        // Results.
        XCTAssertTrue(app.staticTexts[AccessibilityID.resultsScore].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts[AccessibilityID.resultsCorrect].exists)
        XCTAssertTrue(app.staticTexts[AccessibilityID.resultsAccuracy].exists)

        // Replay starts a fresh quiz.
        app.buttons[AccessibilityID.resultsReplay].tap()
        assertRound(number: 1, of: 3)
    }

    func testEmptyLibraryShowsGuidance() throws {
        app.launchArguments = ["-uitest-library", "empty"]
        app.launch()
        let title = app.staticTexts[AccessibilityID.permissionTitle]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        XCTAssertEqual(title.label, "No local songs found")
    }

    func testDeniedLibraryShowsSettingsPath() throws {
        app.launchArguments = ["-uitest-library", "denied"]
        app.launch()
        let title = app.staticTexts[AccessibilityID.permissionTitle]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        XCTAssertEqual(title.label, "Music access is turned off")
        XCTAssertTrue(app.buttons[AccessibilityID.permissionSettings].exists)
    }

    // MARK: - Helpers

    private var revealElement: XCUIElement {
        app.descendants(matching: .any)
            .matching(identifier: AccessibilityID.quizReveal)
            .firstMatch
    }

    private func assertRound(number: Int, of total: Int) {
        let round = app.staticTexts[AccessibilityID.quizRound]
        XCTAssertTrue(round.waitForExistence(timeout: 5))
        let acceptable = ["Round \(number) / \(total)", "Round \(number) of \(total)"]
        XCTAssertTrue(acceptable.contains(round.label), "Expected round \(number) of \(total), got \(round.label)")
        XCTAssertTrue(app.staticTexts[AccessibilityID.quizTimer].exists)
        XCTAssertTrue(app.staticTexts[AccessibilityID.quizScore].exists)
    }

    private func answer(_ text: String) {
        let field = app.textFields[AccessibilityID.quizAnswerField]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        // The trailing newline presses the return key, submitting the answer.
        field.typeText("\(text)\n")
    }

    private func assertFeedback(contains text: String) {
        let feedback = app.staticTexts[AccessibilityID.quizFeedback]
        XCTAssertTrue(feedback.waitForExistence(timeout: 5))
        XCTAssertTrue(feedback.label.contains(text), "Expected feedback containing \(text), got \(feedback.label)")
    }
}

private enum AccessibilityID {
    static let homeStartQuiz = "home.startQuiz"
    static let homeTrackCount = "home.trackCount"
    static let permissionTitle = "permission.title"
    static let permissionSettings = "permission.settings"
    static let quizRound = "quiz.round"
    static let quizTimer = "quiz.timer"
    static let quizScore = "quiz.score"
    static let quizAnswerField = "quiz.answerField"
    static let quizSubmit = "quiz.submit"
    static let quizSkip = "quiz.skip"
    static let quizNext = "quiz.next"
    static let quizReveal = "quiz.reveal"
    static let quizFeedback = "quiz.feedback"
    static let resultsScore = "results.score"
    static let resultsCorrect = "results.correct"
    static let resultsAccuracy = "results.accuracy"
    static let resultsReplay = "results.replay"
}
