import XCTest

final class E2ETests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    // MARK: - SC-024: App launch — initial screen

    func testSC024_AppLaunchShowsInitialScreen() throws {
        // Verify NavigationStack with "Notes" title
        let navTitle = app.navigationBars["Notes"]
        XCTAssertTrue(navTitle.waitForExistence(timeout: 5), "Navigation bar with title 'Notes' should exist")

        // Verify "Notes App" text
        let notesAppText = app.staticTexts["Notes App"]
        XCTAssertTrue(notesAppText.waitForExistence(timeout: 5), "Text 'Notes App' should be visible")

        // Verify welcome message
        let welcomeText = app.staticTexts["Welcome to the Notes App"]
        XCTAssertTrue(welcomeText.waitForExistence(timeout: 5), "Welcome message should be visible")
    }

    // MARK: - SC-025: Create note — current date display

    func testSC025_CreateNoteShowsCurrentDate() throws {
        // Navigate to create note screen
        let createButton = app.buttons["create_note_button"]
        XCTAssertTrue(createButton.waitForExistence(timeout: 5), "Create note button should exist")
        createButton.tap()

        // Verify "New Note" navigation title
        let navTitle = app.navigationBars["New Note"]
        XCTAssertTrue(navTitle.waitForExistence(timeout: 5), "New Note screen should be displayed")

        // Verify date is displayed (CreatedDateView with caption style, gray color)
        // The date has accessibility label "Created on DD.MM.YYYY HH:mm"
        let datePredicate = NSPredicate(format: "label BEGINSWITH 'Created on'")
        let dateElement = app.staticTexts.element(matching: datePredicate)
        XCTAssertTrue(dateElement.waitForExistence(timeout: 5), "Created date should be displayed")

        // Verify date format DD.MM.YYYY HH:mm
        let label = dateElement.label
        let datePattern = "\\d{2}\\.\\d{2}\\.\\d{4} \\d{2}:\\d{2}"
        let regex = try NSRegularExpression(pattern: datePattern)
        let range = NSRange(label.startIndex..., in: label)
        XCTAssertTrue(regex.firstMatch(in: label, range: range) != nil, "Date should match DD.MM.YYYY HH:mm format")

        // Fill title and content
        let titleField = app.textFields.element(matching: NSPredicate(format: "label == 'Note title'"))
        XCTAssertTrue(titleField.waitForExistence(timeout: 5))
        titleField.tap()
        titleField.typeText("Тестовая iOS заметка")

        let contentField = app.textViews.element(matching: NSPredicate(format: "label == 'Note content'"))
        XCTAssertTrue(contentField.waitForExistence(timeout: 5))
        contentField.tap()
        contentField.typeText("Содержимое заметки")
    }

    // MARK: - SC-026: Edit note — date from data

    func testSC026_EditNoteShowsStoredDate() throws {
        // Navigate to an existing note
        let noteCell = app.cells.firstMatch
        XCTAssertTrue(noteCell.waitForExistence(timeout: 5), "A note cell should exist in the list")
        noteCell.tap()

        // Verify edit screen
        let navTitle = app.navigationBars["Edit Note"]
        XCTAssertTrue(navTitle.waitForExistence(timeout: 5), "Edit Note screen should be displayed")

        // Verify date is displayed
        let datePredicate = NSPredicate(format: "label BEGINSWITH 'Created on'")
        let dateElement = app.staticTexts.element(matching: datePredicate)
        XCTAssertTrue(dateElement.waitForExistence(timeout: 5), "Created date should be displayed")

        let originalDate = dateElement.label

        // Verify date format
        let datePattern = "\\d{2}\\.\\d{2}\\.\\d{4} \\d{2}:\\d{2}"
        let regex = try NSRegularExpression(pattern: datePattern)
        let range = NSRange(originalDate.startIndex..., in: originalDate)
        XCTAssertTrue(regex.firstMatch(in: originalDate, range: range) != nil, "Date should match DD.MM.YYYY HH:mm format")

        // Edit the title
        let titleField = app.textFields.element(matching: NSPredicate(format: "label == 'Note title'"))
        XCTAssertTrue(titleField.waitForExistence(timeout: 5))
        titleField.tap()
        titleField.clearAndTypeText("Updated Title")
    }

    // MARK: - SC-027: Delete note

    func testSC027_DeleteNote() throws {
        // Count notes in list
        let initialCellCount = app.cells.count

        // Swipe to delete first note
        let firstCell = app.cells.firstMatch
        XCTAssertTrue(firstCell.waitForExistence(timeout: 5), "At least one note should exist")
        firstCell.swipeLeft()

        let deleteButton = app.buttons["Delete"]
        if deleteButton.waitForExistence(timeout: 3) {
            deleteButton.tap()
        }

        // Verify count decreased
        let finalCellCount = app.cells.count
        XCTAssertLessThan(finalCellCount, initialCellCount, "Note count should decrease after deletion")
    }
}

extension XCUIElement {
    func clearAndTypeText(_ text: String) {
        guard let stringValue = self.value as? String else {
            self.typeText(text)
            return
        }
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        self.typeText(deleteString)
        self.typeText(text)
    }
}
