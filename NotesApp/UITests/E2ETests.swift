import XCTest

final class E2ETests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()

        // Forward BASE_URL and DEV_TOKEN from the test runner environment
        // so the app's APIService can reach the backend.
        // Default to port 4000 to match the allocated app port.
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

    // MARK: - SC-005: Search filters notes by title

    func testSC005_searchFiltersNotes() {
        // Add notes and wait for each to appear (API calls are async)
        addNote("Покупки")
        XCTAssertTrue(app.staticTexts["Покупки"].waitForExistence(timeout: 10), "First note should appear")

        addNote("Работа")
        XCTAssertTrue(app.staticTexts["Работа"].waitForExistence(timeout: 10), "Second note should appear")

        addNote("Покупки на выходные")
        XCTAssertTrue(app.staticTexts["Покупки на выходные"].waitForExistence(timeout: 10), "Third note should appear")

        // Verify all 3 notes present
        assertCounterEquals("Всего заметок: 3")

        // Tap search field and type
        let search = searchField
        XCTAssertTrue(search.waitForExistence(timeout: 5), "Search field should exist")
        search.tap()
        search.typeText("Покупки")

        // Verify filtered counter
        assertCounterEquals("Найдено: 2 из 3")

        // Verify matching notes visible
        let list = notesList
        XCTAssertTrue(list.waitForExistence(timeout: 5))
        XCTAssertEqual(list.cells.count, 2, "Only matching notes should be visible")
    }

    // MARK: - SC-006: Clear search shows all notes

    func testSC006_clearSearchShowsAllNotes() {
        // Add notes and wait for each to appear (API calls are async)
        addNote("Заметка A")
        XCTAssertTrue(app.staticTexts["Заметка A"].waitForExistence(timeout: 10), "First note should appear")

        addNote("Заметка B")
        XCTAssertTrue(app.staticTexts["Заметка B"].waitForExistence(timeout: 10), "Second note should appear")

        assertCounterEquals("Всего заметок: 2")

        // Search
        let search = searchField
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("Заметка A")

        // Verify filter applied
        assertCounterEquals("Найдено: 1 из 2")

        // Clear search by selecting all text and deleting it
        search.tap()
        search.press(forDuration: 1.0)
        let selectAll = app.menuItems["Select All"]
        if selectAll.waitForExistence(timeout: 3) {
            selectAll.tap()
            search.typeText(String(XCUIKeyboardKey.delete.rawValue))
        } else {
            // Fallback: use the clear button inside the search field
            let clearButton = search.buttons["Clear text"]
            if clearButton.waitForExistence(timeout: 3) {
                clearButton.tap()
            }
        }

        // Dismiss the search bar by tapping the Cancel button
        // Try multiple possible labels for the Cancel button (depends on locale)
        let cancelButton = app.buttons.matching(
            NSPredicate(format: "label IN %@", ["Cancel", "Отмена", "Отменить"])
        ).firstMatch
        if cancelButton.waitForExistence(timeout: 5) {
            cancelButton.tap()
        } else {
            // Fallback: tap on the navigation title area to dismiss search
            let navBar = app.navigationBars.firstMatch
            if navBar.waitForExistence(timeout: 3) {
                navBar.tap()
            }
        }

        // Wait for SwiftUI to re-render after search dismissal
        sleep(2)

        // Verify all notes shown again
        let counter = notesCounter
        XCTAssertTrue(counter.waitForExistence(timeout: 5))
        assertCounterEquals("Всего заметок: 2")

        let list = notesList
        XCTAssertTrue(list.waitForExistence(timeout: 5))
        XCTAssertEqual(list.cells.count, 2, "All notes should be visible after clearing search")
    }

    // MARK: - SC-007: Search with no results

    func testSC007_searchNoResults() {
        // Add notes
        addNote("Молоко")
        addNote("Хлеб")

        assertCounterEquals("Всего заметок: 2")

        // Search for non-existing text
        let search = searchField
        XCTAssertTrue(search.waitForExistence(timeout: 5), "Search field should exist")
        search.tap()
        search.typeText("Несуществующая")

        // Verify filtered counter shows 0
        assertCounterEquals("Найдено: 0 из 2")

        // Verify list is empty
        let list = notesList
        XCTAssertTrue(list.waitForExistence(timeout: 5))
        XCTAssertEqual(list.cells.count, 0, "No notes should be visible for non-matching search")
    }
}
