import XCTest

final class SearchE2ETests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()

        // Forward BASE_URL and DEV_TOKEN from the test runner environment
        // so the app's APIService can reach the backend.
        var env: [String: String] = [:]
        env["BASE_URL"] = ProcessInfo.processInfo.environment["BASE_URL"] ?? "http://localhost:4000"
        env["DEV_TOKEN"] = ProcessInfo.processInfo.environment["DEV_TOKEN"] ?? ""
        app.launchEnvironment = env

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
        // Wait for initial fetchNotes to complete before adding notes
        assertCounterEquals("Всего заметок: 0")

        // Add a note with mixed case
        addNote("Важная Заметка")

        // Wait for note to appear after API call completes
        let addedNote = app.staticTexts["Важная Заметка"]
        XCTAssertTrue(addedNote.waitForExistence(timeout: 10), "Added note should appear in the list")

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

        // Clear search text by selecting all and deleting, then type uppercase
        search.tap()
        search.press(forDuration: 1.0)
        let selectAll = app.menuItems["Select All"]
        if selectAll.waitForExistence(timeout: 3) {
            selectAll.tap()
            search.typeText(String(XCUIKeyboardKey.delete.rawValue))
        } else {
            // Fallback: delete characters one by one
            let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: 20)
            search.typeText(deleteString)
        }

        // Wait for search to clear and re-enter uppercase query
        sleep(1)
        let searchForUppercase = searchField
        XCTAssertTrue(searchForUppercase.waitForExistence(timeout: 5))
        searchForUppercase.tap()
        searchForUppercase.typeText("ВАЖНАЯ ЗАМЕТКА")

        // Verify match found with uppercase
        assertCounterEquals("Найдено: 1 из 1")
        XCTAssertTrue(matchedNote.waitForExistence(timeout: 5), "Note should be visible with uppercase search")
    }
}
