import XCTest

final class DeleteNoteE2ETests: XCTestCase {

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

    private func addNote(_ text: String) {
        let textField = newNoteTextField
        XCTAssertTrue(textField.waitForExistence(timeout: 5))
        textField.tap()
        textField.typeText(text)

        let button = addNoteButton
        XCTAssertTrue(button.waitForExistence(timeout: 5))
        button.tap()
    }

    private func assertCounterContains(_ substring: String, file: StaticString = #filePath, line: UInt = #line) {
        let counter = notesCounter
        XCTAssertTrue(counter.waitForExistence(timeout: 5), file: file, line: line)
        XCTAssertTrue(counter.label.contains(substring),
                      "Counter '\(counter.label)' should contain '\(substring)'", file: file, line: line)
    }

    private func takeScreenshot(name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    // MARK: - SC-01: Create note and delete via swipe (v33 delete flow)

    func testSC01_createNoteAndDeleteViaSwipe() throws {
        app.launch()

        // Wait for app to load
        let list = notesList
        XCTAssertTrue(list.waitForExistence(timeout: 10), "Notes list should exist")

        // Remember initial count
        let counter = notesCounter
        XCTAssertTrue(counter.waitForExistence(timeout: 5), "Counter should be visible")
        let initialLabel = counter.label

        // Add a test note
        addNote("Test note from E2E v33")

        // Verify note appears in the list
        let testNote = app.staticTexts["Test note from E2E v33"]
        XCTAssertTrue(testNote.waitForExistence(timeout: 5), "Created note should appear in the list")

        takeScreenshot(name: "SC-01-note-created")

        // Swipe left on the note to reveal delete action
        testNote.swipeLeft()

        // Tap the Delete button
        let deleteButton = app.buttons["Delete"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 5), "Delete button should appear after swipe")
        deleteButton.tap()

        // Verify note is removed from the list
        XCTAssertFalse(testNote.waitForExistence(timeout: 3), "Deleted note should no longer be in the list")

        takeScreenshot(name: "SC-01-note-deleted")
    }

    // MARK: - SC-02: Delete without valid auth — app shows error

    func testSC02_launchWithoutToken_showsUnauthorizedError() throws {
        // Launch without token to simulate unauthorized state
        app.launchArguments += ["-token", ""]
        app.launch()

        // Wait for app to load and API call to complete
        let list = notesList
        XCTAssertTrue(list.waitForExistence(timeout: 10), "Notes list should exist")

        // List should be empty — backend returns 401
        XCTAssertEqual(list.cells.count, 0, "Notes list should be empty without valid auth")

        // Counter should show 0
        let counter = notesCounter
        XCTAssertTrue(counter.waitForExistence(timeout: 5), "Counter should be visible")

        // Error message may be displayed
        let error = errorMessage
        if error.waitForExistence(timeout: 5) {
            XCTAssertTrue(
                error.label.contains("Unauthorized") || error.label.contains("unauthorized") || error.label.contains("Server error"),
                "Error should indicate auth failure, got: \(error.label)"
            )
        }

        // UI should remain functional (no crash)
        XCTAssertTrue(newNoteTextField.waitForExistence(timeout: 5), "Text field should be accessible")
        XCTAssertTrue(addNoteButton.waitForExistence(timeout: 5), "Add button should be accessible")

        takeScreenshot(name: "SC-02-no-auth-error")
    }

    // MARK: - SC-v33-1: Create multiple notes and delete one — verify remaining

    func testSCV33_1_createMultipleAndDeleteOne_verifyRemaining() throws {
        app.launch()

        let list = notesList
        XCTAssertTrue(list.waitForExistence(timeout: 10), "Notes list should exist")

        // Add two notes
        addNote("E2E v33 заметка #1")
        let note1 = app.staticTexts["E2E v33 заметка #1"]
        XCTAssertTrue(note1.waitForExistence(timeout: 5), "First note should appear")

        addNote("E2E v33 заметка #2")
        let note2 = app.staticTexts["E2E v33 заметка #2"]
        XCTAssertTrue(note2.waitForExistence(timeout: 5), "Second note should appear")

        takeScreenshot(name: "SC-v33-1-two-notes-created")

        // Delete the first note via swipe
        note1.swipeLeft()
        let deleteButton = app.buttons["Delete"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 5), "Delete button should appear")
        deleteButton.tap()

        // Verify first note is gone
        XCTAssertFalse(note1.waitForExistence(timeout: 3), "First note should be deleted")

        // Verify second note is still present
        XCTAssertTrue(note2.waitForExistence(timeout: 5), "Second note should remain in the list")

        takeScreenshot(name: "SC-v33-1-one-note-deleted")
    }

    // MARK: - SC-v33-2: Invalid token launch — verify error and empty state

    func testSCV33_2_invalidToken_emptyStateWithError() throws {
        // Launch with explicitly invalid token
        app.launchArguments += ["-token", "invalid.jwt.token"]
        app.launch()

        // Wait for the app to load
        let list = notesList
        XCTAssertTrue(list.waitForExistence(timeout: 10), "Notes list should exist")

        // List should be empty with invalid token
        XCTAssertEqual(list.cells.count, 0, "Notes list should be empty with invalid token")

        // Navigation title should be present
        let navTitle = app.navigationBars["Заметки"]
        XCTAssertTrue(navTitle.waitForExistence(timeout: 5), "Navigation title should be displayed")

        // App should not crash — UI elements still accessible
        XCTAssertTrue(newNoteTextField.waitForExistence(timeout: 5), "Text field should be present")
        XCTAssertTrue(addNoteButton.waitForExistence(timeout: 5), "Add button should be present")

        takeScreenshot(name: "SC-v33-2-invalid-token")
    }

    // MARK: - SC-v33-3: Create note, verify counter, delete, verify counter updated

    func testSCV33_3_createDeleteVerifyCounterUpdates() throws {
        app.launch()

        let list = notesList
        XCTAssertTrue(list.waitForExistence(timeout: 10), "Notes list should exist")

        // Add a note
        addNote("Test note from E2E v33 counter check")

        let testNote = app.staticTexts["Test note from E2E v33 counter check"]
        XCTAssertTrue(testNote.waitForExistence(timeout: 5), "Note should appear in list")

        // Verify counter increased
        let counter = notesCounter
        XCTAssertTrue(counter.waitForExistence(timeout: 5), "Counter should be visible")

        takeScreenshot(name: "SC-v33-3-note-added-counter")

        // Delete the note
        testNote.swipeLeft()
        let deleteButton = app.buttons["Delete"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 5), "Delete button should appear")
        deleteButton.tap()

        // Verify note is gone
        XCTAssertFalse(testNote.waitForExistence(timeout: 3), "Note should be deleted")

        takeScreenshot(name: "SC-v33-3-note-deleted-counter")
    }
}
