import XCTest

final class E2ETests: XCTestCase {

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

    // MARK: - SC-001: Initial state

    func testSC001_initialState() {
        // Navigation title exists
        let navTitle = app.navigationBars["Заметки"]
        XCTAssertTrue(navTitle.waitForExistence(timeout: 5), "Navigation title should exist")

        // Counter shows 0
        assertCounterEquals("Всего заметок: 0")

        // Notes list exists and is empty
        let list = notesList
        XCTAssertTrue(list.waitForExistence(timeout: 5), "Notes list should exist")
        XCTAssertEqual(list.cells.count, 0, "Notes list should be empty initially")

        // Text field exists
        let textField = newNoteTextField
        XCTAssertTrue(textField.waitForExistence(timeout: 5), "Text field should exist")

        // Add button exists
        let button = addNoteButton
        XCTAssertTrue(button.waitForExistence(timeout: 5), "Add button should exist")
    }

    // MARK: - SC-002: Adding notes updates counter

    func testSC002_addNotesUpdatesCounter() {
        // Initial counter is 0
        assertCounterEquals("Всего заметок: 0")

        // Add first note
        addNote("Первая заметка")

        // Verify note appears in the list
        let firstNote = app.staticTexts["Первая заметка"]
        XCTAssertTrue(firstNote.waitForExistence(timeout: 5), "First note should appear in the list")

        // Counter should be 1
        assertCounterEquals("Всего заметок: 1")

        // Add second note
        addNote("Вторая заметка")

        // Verify second note appears
        let secondNote = app.staticTexts["Вторая заметка"]
        XCTAssertTrue(secondNote.waitForExistence(timeout: 5), "Second note should appear in the list")

        // Counter should be 2
        assertCounterEquals("Всего заметок: 2")
    }

    // MARK: - SC-003: Swipe to delete updates counter

    func testSC003_swipeToDeleteUpdatesCounter() {
        // Add two notes
        addNote("Заметка X")
        let noteX = app.staticTexts["Заметка X"]
        XCTAssertTrue(noteX.waitForExistence(timeout: 5))

        addNote("Заметка Y")
        let noteY = app.staticTexts["Заметка Y"]
        XCTAssertTrue(noteY.waitForExistence(timeout: 5))

        // Counter should be 2
        assertCounterEquals("Всего заметок: 2")

        // Swipe left on "Заметка X" to delete
        noteX.swipeLeft()
        let deleteButton = app.buttons["Delete"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 5), "Delete button should appear after swipe")
        deleteButton.tap()

        // Verify "Заметка X" is gone
        XCTAssertFalse(noteX.waitForExistence(timeout: 3), "Deleted note should no longer exist")

        // Counter should be 1
        assertCounterEquals("Всего заметок: 1")

        // "Заметка Y" should still be present
        XCTAssertTrue(noteY.waitForExistence(timeout: 5), "Remaining note should still exist")
    }

    // MARK: - SC-004: Empty and whitespace-only notes are rejected

    func testSC004_emptyAndWhitespaceNotesRejected() {
        // Initial counter is 0
        assertCounterEquals("Всего заметок: 0")

        // Tap add button without entering text
        let button = addNoteButton
        XCTAssertTrue(button.waitForExistence(timeout: 5))
        button.tap()

        // Counter should still be 0
        assertCounterEquals("Всего заметок: 0")

        // Type whitespace-only text
        let textField = newNoteTextField
        XCTAssertTrue(textField.waitForExistence(timeout: 5))
        textField.tap()
        textField.typeText("   ")

        // Tap add
        button.tap()

        // Counter should still be 0
        assertCounterEquals("Всего заметок: 0")
    }
}
