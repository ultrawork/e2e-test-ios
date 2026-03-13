import XCTest

final class E2ETests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    // SC-301: Create note screen - form elements and initial counter state
    func testSC301_NoteEditScreen_FormElementsAndInitialCounter() throws {
        // Navigate to NoteEditView via NavigationLink
        let createButton = app.buttons["create_note_button"]
        XCTAssertTrue(createButton.waitForExistence(timeout: 5))
        createButton.tap()

        // Verify title text field exists
        let titleField = app.textFields["note_title_field"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 5))

        // Verify content text editor exists
        let contentEditor = app.textViews["note_content_editor"]
        XCTAssertTrue(contentEditor.waitForExistence(timeout: 5))

        // Verify character counter shows "0 символов"
        let counter = app.staticTexts["character_counter"]
        XCTAssertTrue(counter.waitForExistence(timeout: 5))
        XCTAssertEqual(counter.label, "0 символов")

        // Verify save button exists
        let saveButton = app.buttons["save_button"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5))
    }

    // SC-302: Character counter updates in real time
    func testSC302_CharacterCounter_UpdatesInRealTime() throws {
        // Navigate to NoteEditView
        let createButton = app.buttons["create_note_button"]
        XCTAssertTrue(createButton.waitForExistence(timeout: 5))
        createButton.tap()

        let contentEditor = app.textViews["note_content_editor"]
        XCTAssertTrue(contentEditor.waitForExistence(timeout: 5))

        let counter = app.staticTexts["character_counter"]
        XCTAssertTrue(counter.waitForExistence(timeout: 5))

        // Initial state: 0 символов
        XCTAssertEqual(counter.label, "0 символов")

        // Type "Hello" (5 characters)
        contentEditor.tap()
        contentEditor.typeText("Hello")
        XCTAssertEqual(counter.label, "5 символов")

        // Append " World" (total 11 characters)
        contentEditor.typeText(" World")
        XCTAssertEqual(counter.label, "11 символов")

        // Clear text
        let textValue = contentEditor.value as? String ?? ""
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: textValue.count)
        contentEditor.typeText(deleteString)
        XCTAssertEqual(counter.label, "0 символов")
    }

    // SC-303: Character counter accessibility for VoiceOver
    func testSC303_CharacterCounter_AccessibilityLabel() throws {
        // Navigate to NoteEditView
        let createButton = app.buttons["create_note_button"]
        XCTAssertTrue(createButton.waitForExistence(timeout: 5))
        createButton.tap()

        let contentEditor = app.textViews["note_content_editor"]
        XCTAssertTrue(contentEditor.waitForExistence(timeout: 5))

        let counter = app.staticTexts["character_counter"]
        XCTAssertTrue(counter.waitForExistence(timeout: 5))

        // Type "Заметка" (7 characters)
        contentEditor.tap()
        contentEditor.typeText("Заметка")

        // Verify accessibility label contains "7 символов"
        XCTAssertEqual(counter.label, "7 символов")

        // Append " тест" (total 12 characters)
        contentEditor.typeText(" тест")
        XCTAssertEqual(counter.label, "12 символов")
    }
}
