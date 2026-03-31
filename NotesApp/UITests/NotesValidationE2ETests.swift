import XCTest

final class NotesValidationE2ETests: XCTestCase {

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

    private var searchField: XCUIElement {
        app.searchFields.firstMatch
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

    // MARK: - SC-04: Search filters notes and shows counter

    func testSC04_searchFiltersNotesAndShowsCounter() {
        // Add three notes as specified in scenario
        addNote("Покупки")
        let note1 = app.staticTexts["Покупки"]
        XCTAssertTrue(note1.waitForExistence(timeout: 5), "First note should appear")

        addNote("Работа")
        let note2 = app.staticTexts["Работа"]
        XCTAssertTrue(note2.waitForExistence(timeout: 5), "Second note should appear")

        addNote("Покупки на выходные")
        let note3 = app.staticTexts["Покупки на выходные"]
        XCTAssertTrue(note3.waitForExistence(timeout: 5), "Third note should appear")

        // Verify counter shows all 3 notes
        assertCounterEquals("Всего заметок: 3")

        // Tap search field and type filter query
        let search = searchField
        XCTAssertTrue(search.waitForExistence(timeout: 5), "Search field should exist")
        search.tap()
        search.typeText("Покупки")

        // Verify filtered counter switches to "Найдено: 2 из 3"
        assertCounterEquals("Найдено: 2 из 3")

        // Verify only 2 matching cells are visible
        let list = notesList
        XCTAssertTrue(list.waitForExistence(timeout: 5))
        XCTAssertEqual(list.cells.count, 2, "Only matching notes should be visible")

        // Verify "Работа" is not displayed
        let nonMatchingNote = app.staticTexts["Работа"]
        XCTAssertFalse(nonMatchingNote.exists, "Non-matching note 'Работа' should not be visible")

        takeScreenshot(name: "SC-04-search-filters-notes")
    }

    // MARK: - SC-05: Empty and whitespace-only notes are not added

    func testSC05_emptyAndWhitespaceNoteNotAdded() {
        // Verify initial counter is 0
        assertCounterEquals("Всего заметок: 0")

        // Tap add button without entering any text
        let button = addNoteButton
        XCTAssertTrue(button.waitForExistence(timeout: 5))
        button.tap()

        // Counter should still be 0
        assertCounterEquals("Всего заметок: 0")

        // Verify list is still empty
        let list = notesList
        XCTAssertTrue(list.waitForExistence(timeout: 5))
        XCTAssertEqual(list.cells.count, 0, "List should remain empty after adding empty note")

        // Type whitespace-only text (three spaces)
        let textField = newNoteTextField
        XCTAssertTrue(textField.waitForExistence(timeout: 5))
        textField.tap()
        textField.typeText("   ")

        // Tap add
        button.tap()

        // Counter should still be 0
        assertCounterEquals("Всего заметок: 0")

        // List should still be empty
        XCTAssertEqual(list.cells.count, 0, "List should remain empty after adding whitespace-only note")

        takeScreenshot(name: "SC-05-empty-whitespace-rejected")
    }
}
