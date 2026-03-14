import XCTest

final class SearchE2ETests: XCTestCase {

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

    // MARK: - SC-008: Case-insensitive search

    func testSC008_searchIsCaseInsensitive() {
        // Add a note with mixed case
        addNote("Важная Заметка")

        // Verify initial state
        assertCounterEquals("Всего заметок: 1")

        // Search with lowercase
        let search = searchField
        XCTAssertTrue(search.waitForExistence(timeout: 5), "Search field should exist")
        search.tap()
        search.typeText("важная заметка")

        // Verify match found
        assertCounterEquals("Найдено: 1 из 1")

        let matchedNote = app.staticTexts["Важная Заметка"]
        XCTAssertTrue(matchedNote.waitForExistence(timeout: 5), "Note should be visible with lowercase search")

        // Clear search and try uppercase
        let clearButton = search.buttons["Clear text"]
        XCTAssertTrue(clearButton.waitForExistence(timeout: 5))
        clearButton.tap()

        // Re-tap search field after clearing to ensure it has focus
        let searchAfterClear = searchField
        XCTAssertTrue(searchAfterClear.waitForExistence(timeout: 5))
        searchAfterClear.tap()
        sleep(1)
        searchAfterClear.typeText("ВАЖНАЯ ЗАМЕТКА")

        // Verify match found with uppercase
        assertCounterEquals("Найдено: 1 из 1")
        XCTAssertTrue(matchedNote.waitForExistence(timeout: 5), "Note should be visible with uppercase search")
    }
}
