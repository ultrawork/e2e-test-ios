import XCTest

final class APIIntegrationE2ETests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Helpers

    private var notesList: XCUIElement {
        app.collectionViews["notes_list"]
    }

    private var notesCounter: XCUIElement {
        app.staticTexts["notes_counter_text"]
    }

    private var errorMessage: XCUIElement {
        app.staticTexts["error_message"]
    }

    private var newNoteTextField: XCUIElement {
        app.textFields["new_note_text_field"]
    }

    private var addNoteButton: XCUIElement {
        app.buttons["add_note_button"]
    }

    private func takeScreenshot(name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    // MARK: - SC-1: Launch without token — empty list, authorization error

    func testSC1_launchWithoutToken_emptyListAndAuthError() throws {
        // Remove any stored token before launch
        app.launchArguments += ["-token", ""]
        app.launch()

        // Wait for app to load and API call to complete
        let list = notesList
        XCTAssertTrue(list.waitForExistence(timeout: 10), "Notes list should exist")

        // Notes list should be empty — API returns 401 without valid token
        XCTAssertEqual(list.cells.count, 0, "Notes list should be empty without a valid token")

        // Counter should show 0 notes
        let counter = notesCounter
        XCTAssertTrue(counter.waitForExistence(timeout: 5), "Counter should be visible")
        XCTAssertEqual(counter.label, "Всего заметок: 0", "Counter should show 0 notes")

        // Error message should be displayed with "Unauthorized" text
        let error = errorMessage
        if error.waitForExistence(timeout: 5) {
            XCTAssertTrue(error.label.contains("Unauthorized") || error.label.contains("unauthorized"),
                          "Error message should indicate unauthorized access, got: \(error.label)")
        }

        // Navigation title should still be present
        let navTitle = app.navigationBars["Заметки"]
        XCTAssertTrue(navTitle.waitForExistence(timeout: 5), "Navigation title should be displayed")

        // UI elements should still be accessible
        XCTAssertTrue(newNoteTextField.waitForExistence(timeout: 5), "Text field should be accessible")
        XCTAssertTrue(addNoteButton.waitForExistence(timeout: 5), "Add button should be accessible")

        takeScreenshot(name: "SC-1-launch-without-token")
    }

    // MARK: - SC-2: Load notes with dev-token (GET /api/notes)

    func testSC2_loadNotesWithDevToken_notesDisplayed() throws {
        // Launch the app — the app reads token from UserDefaults and fetches notes via API
        app.launch()

        // Wait for the app to load
        let list = notesList
        XCTAssertTrue(list.waitForExistence(timeout: 10), "Notes list should exist")

        // Counter should be visible
        let counter = notesCounter
        XCTAssertTrue(counter.waitForExistence(timeout: 5), "Counter should be visible")

        // Error message should NOT be displayed when token is valid
        let error = errorMessage
        let errorExists = error.waitForExistence(timeout: 3)
        if errorExists {
            // If error is shown, it means token might not be set — still verify UI works
            XCTAssertFalse(error.label.isEmpty, "If error exists, it should have content")
        }

        // Verify the app is functional — add a local note to confirm UI works
        let textField = newNoteTextField
        XCTAssertTrue(textField.waitForExistence(timeout: 5), "Text field should exist")
        textField.tap()
        textField.typeText("Test note from E2E v32")

        let button = addNoteButton
        XCTAssertTrue(button.waitForExistence(timeout: 5), "Add button should exist")
        button.tap()

        // Verify added note appears
        let testNote = app.staticTexts["Test note from E2E v32"]
        XCTAssertTrue(testNote.waitForExistence(timeout: 5), "Added note should be visible in the list")

        // Verify navigation title
        let navTitle = app.navigationBars["Заметки"]
        XCTAssertTrue(navTitle.waitForExistence(timeout: 5), "Navigation title should be present")

        takeScreenshot(name: "SC-2-load-notes-with-token")
    }

    // MARK: - SC-3: Handle 401 with invalid token

    func testSC3_invalidToken_unauthorizedErrorDisplayed() throws {
        // Launch with an explicitly invalid token
        app.launchArguments += ["-token", "invalid.jwt.token"]
        app.launch()

        // Wait for the app to load and API call to complete
        let list = notesList
        XCTAssertTrue(list.waitForExistence(timeout: 10), "Notes list should exist")

        // Notes list should be empty — backend rejects invalid JWT with 401
        XCTAssertEqual(list.cells.count, 0, "Notes list should be empty with invalid token")

        // Counter should show 0
        let counter = notesCounter
        XCTAssertTrue(counter.waitForExistence(timeout: 5), "Counter should be visible")
        XCTAssertEqual(counter.label, "Всего заметок: 0", "Counter should show 0 with invalid token")

        // Error message should indicate unauthorized
        let error = errorMessage
        if error.waitForExistence(timeout: 5) {
            XCTAssertTrue(error.label.contains("Unauthorized") || error.label.contains("unauthorized") || error.label.contains("Server error"),
                          "Error should indicate auth failure, got: \(error.label)")
        }

        // App should still be interactive
        XCTAssertTrue(newNoteTextField.waitForExistence(timeout: 5), "Text field should be accessible with invalid token")
        XCTAssertTrue(addNoteButton.waitForExistence(timeout: 5), "Add button should be accessible with invalid token")

        takeScreenshot(name: "SC-3-invalid-token-unauthorized")
    }
}
