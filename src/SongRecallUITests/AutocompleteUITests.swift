import XCTest

/// Autocomplete behavior in the quiz answer field.
///
/// Stub library selection order (seed 0): Gamma Song, Beta Song,
/// Alpha Song. Typing "gam" should surface only Gamma Song, which is
/// the current round's answer.
final class AutocompleteUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testSuggestionCommitsAnswer() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-library", "ready"]
        app.launch()

        let startButton = app.buttons["home.startQuiz"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 5))
        startButton.tap()

        let field = app.textFields["quiz.answerField"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText("gam")

        // The row shows title (larger, white) and artist (smaller, grey).
        let suggestion = app.buttons.matching(identifier: "quiz.suggestion").firstMatch
        XCTAssertTrue(suggestion.waitForExistence(timeout: 5))
        XCTAssertEqual(suggestion.label, "Gamma Song, Artist Three")

        suggestion.tap()

        let feedback = app.staticTexts["quiz.feedback"]
        XCTAssertTrue(feedback.waitForExistence(timeout: 5))
        XCTAssertTrue(feedback.label.contains("2x multiplier"), "Got: \(feedback.label)")
    }

    func testNoSuggestionsForNonsenseQuery() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-library", "ready"]
        app.launch()

        let startButton = app.buttons["home.startQuiz"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 5))
        startButton.tap()

        let field = app.textFields["quiz.answerField"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText("zzz")

        XCTAssertFalse(app.buttons.matching(identifier: "quiz.suggestion").firstMatch.exists)
    }
}
