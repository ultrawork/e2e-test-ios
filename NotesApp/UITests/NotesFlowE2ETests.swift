import XCTest

final class NotesFlowE2ETests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Helpers

    private var notesCounter: XCUIElement {
        app.staticTexts["notes_counter_text"]
    }

    private var newNoteTextField: XCUIElement {
        app.textFields["new_note_text_field"]
    }

    private var addNoteButton: XCUIElement {
        app.buttons["add_note_button"]
    }

    private var notesList: XCUIElement {
        app.collectionViews["notes_list"]
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

    // MARK: - SC-1: App launch — empty state, UI elements accessible

    func testSC01_appLaunch_emptyStateWithUIElements() throws {
        // Verify navigation title
        let navTitle = app.navigationBars["Заметки"]
        XCTAssertTrue(navTitle.waitForExistence(timeout: 5), "Navigation title 'Заметки' should be displayed")

        // Verify counter shows 0
        assertCounterEquals("Всего заметок: 0")

        // Verify notes list is empty
        let list = notesList
        XCTAssertTrue(list.waitForExistence(timeout: 5), "Notes list should exist")
        XCTAssertEqual(list.cells.count, 0, "Notes list should be empty on fresh launch")

        // Verify input field and add button are accessible
        XCTAssertTrue(newNoteTextField.waitForExistence(timeout: 5), "Text field should be accessible")
        XCTAssertTrue(addNoteButton.waitForExistence(timeout: 5), "Add button should be accessible")

        takeScreenshot(name: "SC-01-app-launch-empty-state")
    }

    // MARK: - SC-2: Create and display notes with v29 test data

    func testSC02_createAndDisplayNotes() throws {
        // Verify initial empty state
        assertCounterEquals("Всего заметок: 0")

        // Create test note with v29 test data
        addNote("Test note from E2E v29")

        // Verify note appears in the list
        let testNote = app.staticTexts["Test note from E2E v29"]
        XCTAssertTrue(testNote.waitForExistence(timeout: 5), "Test note should appear in list")

        // Verify counter updated
        assertCounterEquals("Всего заметок: 1")

        // Create multiple v29 notes
        addNote("E2E v29 заметка #1")
        let note1 = app.staticTexts["E2E v29 заметка #1"]
        XCTAssertTrue(note1.waitForExistence(timeout: 5), "First v29 note should appear")

        addNote("E2E v29 заметка #2")
        let note2 = app.staticTexts["E2E v29 заметка #2"]
        XCTAssertTrue(note2.waitForExistence(timeout: 5), "Second v29 note should appear")

        // Verify counter reflects all 3 notes
        assertCounterEquals("Всего заметок: 3")

        // Verify list has correct cell count
        let list = notesList
        XCTAssertTrue(list.waitForExistence(timeout: 5))
        XCTAssertEqual(list.cells.count, 3, "List should contain 3 notes")

        takeScreenshot(name: "SC-02-notes-created-and-displayed")
    }

    // MARK: - SC-3: Delete note and verify list updates

    func testSC03_deleteNoteAndVerifyUpdate() throws {
        // Create two notes
        addNote("E2E v29 заметка #1")
        let note1 = app.staticTexts["E2E v29 заметка #1"]
        XCTAssertTrue(note1.waitForExistence(timeout: 5))

        addNote("E2E v29 заметка #2")
        let note2 = app.staticTexts["E2E v29 заметка #2"]
        XCTAssertTrue(note2.waitForExistence(timeout: 5))

        // Verify counter shows 2
        assertCounterEquals("Всего заметок: 2")

        // Swipe to delete first note
        note1.swipeLeft()
        let deleteButton = app.buttons["Delete"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 5), "Delete button should appear after swipe")
        deleteButton.tap()

        // Verify note is deleted
        XCTAssertFalse(note1.waitForExistence(timeout: 3), "Deleted note should no longer exist")

        // Verify remaining note is still present
        XCTAssertTrue(note2.waitForExistence(timeout: 5), "Second note should still be visible")

        // Verify counter updated
        assertCounterEquals("Всего заметок: 1")

        takeScreenshot(name: "SC-03-note-deleted-and-updated")
    }
}
