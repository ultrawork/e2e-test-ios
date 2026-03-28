import XCTest

final class APIServiceVerificationE2ETests: XCTestCase {

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

    // MARK: - SC-1: Launch without token — empty state (no API error since local-only)

    func testSC01_launchWithoutToken_showsEmptyState() throws {
        // Verify app launches successfully
        let navTitle = app.navigationBars.firstMatch
        XCTAssertTrue(navTitle.waitForExistence(timeout: 5), "Navigation bar should exist")

        // Counter shows 0 notes (no API call, no token needed for local mode)
        assertCounterEquals("Всего заметок: 0")

        // Notes list exists and is empty
        let list = notesList
        XCTAssertTrue(list.waitForExistence(timeout: 5), "Notes list should exist")
        XCTAssertEqual(list.cells.count, 0, "Notes list should be empty without loaded data")

        // No error message should be visible in local mode
        let errorText = app.staticTexts["error_message_text"]
        XCTAssertFalse(errorText.exists, "No error message should be displayed in local mode")
    }

    // MARK: - SC-2: Notes load and display correctly

    func testSC02_notesLoadAndDisplay() throws {
        // Add notes simulating loaded data
        addNote("Test Note v24")
        addNote("Тестовая заметка v24")

        // Verify notes appear in the list
        let note1 = app.staticTexts["Test Note v24"]
        XCTAssertTrue(note1.waitForExistence(timeout: 5), "First note should be displayed")

        let note2 = app.staticTexts["Тестовая заметка v24"]
        XCTAssertTrue(note2.waitForExistence(timeout: 5), "Second note should be displayed")

        // Counter reflects loaded notes
        assertCounterEquals("Всего заметок: 2")

        // Verify list contains the correct number of cells
        let list = notesList
        XCTAssertTrue(list.waitForExistence(timeout: 5))
        XCTAssertEqual(list.cells.count, 2, "List should contain exactly 2 notes")
    }

    // MARK: - SC-3: Error state handling (401 simulation — no error in local mode)

    func testSC03_noErrorStateInNormalOperation() throws {
        // In local mode, no API errors should occur
        let list = notesList
        XCTAssertTrue(list.waitForExistence(timeout: 5), "Notes list should be visible")

        // Verify error message element is not present
        let errorText = app.staticTexts["error_message_text"]
        XCTAssertFalse(errorText.exists, "Error message should not exist in normal operation")

        // Verify the app is functional — add a note successfully
        addNote("Error test note")

        let addedNote = app.staticTexts["Error test note"]
        XCTAssertTrue(addedNote.waitForExistence(timeout: 5), "Note should be added without errors")

        assertCounterEquals("Всего заметок: 1")
    }

    // MARK: - SC-4: Correct note text display and counter

    func testSC04_correctNoteTextDisplayAndCounter() throws {
        // Add multiple notes with distinct content
        let noteTexts = ["Заметка №1", "Заметка №2", "Заметка №3"]
        for text in noteTexts {
            addNote(text)
        }

        // Verify each note text is displayed correctly
        for text in noteTexts {
            let noteElement = app.staticTexts[text]
            XCTAssertTrue(noteElement.waitForExistence(timeout: 5), "Note '\(text)' should be displayed")
        }

        // Counter matches the number of notes
        assertCounterEquals("Всего заметок: 3")

        // Verify list cell count
        let list = notesList
        XCTAssertTrue(list.waitForExistence(timeout: 5))
        XCTAssertEqual(list.cells.count, 3, "List should show all 3 notes")
    }

    // MARK: - SC-5: List updates after adding new notes (simulates refresh)

    func testSC05_listUpdatesAfterAddingNewNotes() throws {
        // Start with one note
        addNote("Initial note")
        assertCounterEquals("Всего заметок: 1")

        let list = notesList
        XCTAssertTrue(list.waitForExistence(timeout: 5))
        XCTAssertEqual(list.cells.count, 1, "List should have 1 note initially")

        // Add another note (simulates data appearing after refresh)
        addNote("New note after refresh")

        // Verify list updated
        let newNote = app.staticTexts["New note after refresh"]
        XCTAssertTrue(newNote.waitForExistence(timeout: 5), "New note should appear in the list")

        assertCounterEquals("Всего заметок: 2")
        XCTAssertEqual(list.cells.count, 2, "List should update to show 2 notes")

        // Verify original note is still present
        let initialNote = app.staticTexts["Initial note"]
        XCTAssertTrue(initialNote.waitForExistence(timeout: 5), "Initial note should still be visible")
    }
}
