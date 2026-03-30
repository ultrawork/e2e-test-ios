import XCTest

final class APIServiceE2ETests: XCTestCase {

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

    private func assertCounterEquals(_ expected: String, file: StaticString = #filePath, line: UInt = #line) {
        let counter = notesCounter
        XCTAssertTrue(counter.waitForExistence(timeout: 5), file: file, line: line)
        XCTAssertEqual(counter.label, expected, file: file, line: line)
    }

    private func takeScreenshot(name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    // MARK: - SC-1: Launch without token — empty list, authorization error

    func testSC01_launchWithoutToken_emptyListAndError() throws {
        // Launch app without any token configured
        // Simulates: no token in UserDefaults → API returns 401
        app.launchArguments += ["-noToken", "1"]
        app.launch()

        // Verify the notes list exists
        let list = notesList
        XCTAssertTrue(list.waitForExistence(timeout: 5), "Notes list should exist")

        // Verify list is empty (no notes loaded without valid token)
        XCTAssertEqual(list.cells.count, 0, "Notes list should be empty when no token is provided")

        // Verify counter shows 0 notes
        assertCounterEquals("Всего заметок: 0")

        // Verify navigation title is present
        let navTitle = app.navigationBars["Заметки"]
        XCTAssertTrue(navTitle.waitForExistence(timeout: 5), "Navigation title should be displayed")

        // Verify UI elements are accessible even without auth
        let textField = newNoteTextField
        XCTAssertTrue(textField.waitForExistence(timeout: 5), "Input field should be present")

        let button = addNoteButton
        XCTAssertTrue(button.waitForExistence(timeout: 5), "Add button should be present")

        takeScreenshot(name: "SC-01-launch-without-token")
    }

    // MARK: - SC-2: Load notes with dev-token (GET /api/notes)

    func testSC02_loadNotesWithDevToken_notesDisplayed() throws {
        // Launch app with token configured
        // Simulates: valid dev-token in UserDefaults → API returns notes
        app.launchArguments += ["-hasToken", "1"]
        app.launch()

        // Verify the app launches successfully with notes list
        let list = notesList
        XCTAssertTrue(list.waitForExistence(timeout: 5), "Notes list should exist")

        // Verify counter is visible
        let counter = notesCounter
        XCTAssertTrue(counter.waitForExistence(timeout: 5), "Counter should be visible")

        // Add a test note to verify data flow through ViewModel → View
        addNote("Test note from E2E v28")

        // Verify note appears in the list (content → text mapping)
        let testNote = app.staticTexts["Test note from E2E v28"]
        XCTAssertTrue(testNote.waitForExistence(timeout: 5), "Added note should be visible in the list")

        // Verify counter updated
        assertCounterEquals("Всего заметок: 1")

        // Add second note to verify multiple notes display
        addNote("Second v28 test note")

        let secondNote = app.staticTexts["Second v28 test note"]
        XCTAssertTrue(secondNote.waitForExistence(timeout: 5), "Second note should be visible")

        // Verify counter reflects all notes
        assertCounterEquals("Всего заметок: 2")

        // Verify list has correct number of cells
        XCTAssertEqual(list.cells.count, 2, "List should contain 2 notes")

        takeScreenshot(name: "SC-02-load-notes-with-token")
    }

    // MARK: - SC-3: Handle 401 with invalid token

    func testSC03_invalidToken_unauthorizedError() throws {
        // Launch app with invalid token
        // Simulates: invalid JWT in UserDefaults → API returns 401 Unauthorized
        app.launchArguments += ["-invalidToken", "1"]
        app.launch()

        // Verify the app still launches and shows UI
        let navTitle = app.navigationBars["Заметки"]
        XCTAssertTrue(navTitle.waitForExistence(timeout: 5), "Navigation should be present even with invalid token")

        // Verify notes list exists but is empty
        let list = notesList
        XCTAssertTrue(list.waitForExistence(timeout: 5), "Notes list should exist")
        XCTAssertEqual(list.cells.count, 0, "Notes list should be empty with invalid token")

        // Verify counter shows 0
        assertCounterEquals("Всего заметок: 0")

        // Verify the app is still functional — user can still interact
        let textField = newNoteTextField
        XCTAssertTrue(textField.waitForExistence(timeout: 5), "Input field should still be accessible")

        let button = addNoteButton
        XCTAssertTrue(button.waitForExistence(timeout: 5), "Add button should still be accessible")

        takeScreenshot(name: "SC-03-invalid-token-unauthorized")
    }
}
