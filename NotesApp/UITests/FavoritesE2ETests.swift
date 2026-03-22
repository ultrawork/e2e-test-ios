import XCTest

final class FavoritesE2ETests: XCTestCase {

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

    private var notesList: XCUIElement {
        app.collectionViews["notes_list"]
    }

    private var newNoteTextField: XCUIElement {
        app.textFields["new_note_text_field"]
    }

    private var addNoteButton: XCUIElement {
        app.buttons["add_note_button"]
    }

    private var favoritesFilterButton: XCUIElement {
        app.buttons["favorites_filter_button"]
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

    private func starButton(forNoteWithText text: String) -> XCUIElement {
        let cell = notesList.cells.containing(.staticText, identifier: text).firstMatch
        XCTAssertTrue(cell.waitForExistence(timeout: 5), "Cell with text '\(text)' should exist")
        let star = cell.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "favorite_button_")
        ).firstMatch
        XCTAssertTrue(star.waitForExistence(timeout: 5), "Star button should exist in cell '\(text)'")
        return star
    }

    // MARK: - SC-009: Toggle favorite star

    func testSC009_toggleFavoriteStar() {
        // Добавить заметку
        addNote("A")

        let noteA = app.staticTexts["A"]
        XCTAssertTrue(noteA.waitForExistence(timeout: 5), "Note 'A' should appear")

        // Найти кнопку звезды
        let star = starButton(forNoteWithText: "A")

        // Первый тап — отметить как избранное
        star.tap()
        XCTAssertEqual(star.label, "Убрать из избранного", "After tap, label should be 'Убрать из избранного'")

        // Второй тап — снять избранное
        star.tap()
        XCTAssertEqual(star.label, "Добавить в избранное", "After second tap, label should be 'Добавить в избранное'")
    }

    // MARK: - SC-010: Favorites filter shows only favorited notes

    func testSC010_favoritesFilterShowsOnlyFavorited() {
        // Добавить три заметки
        addNote("A")
        let noteA = app.staticTexts["A"]
        XCTAssertTrue(noteA.waitForExistence(timeout: 5))

        addNote("B")
        let noteB = app.staticTexts["B"]
        XCTAssertTrue(noteB.waitForExistence(timeout: 5))

        addNote("C")
        let noteC = app.staticTexts["C"]
        XCTAssertTrue(noteC.waitForExistence(timeout: 5))

        // Отметить "B" как избранную
        let starB = starButton(forNoteWithText: "B")
        starB.tap()

        // Включить фильтр "только избранные"
        let filterButton = favoritesFilterButton
        XCTAssertTrue(filterButton.waitForExistence(timeout: 5))
        filterButton.tap()

        // Проверить: в списке 1 ячейка и видна "B"
        let list = notesList
        XCTAssertTrue(list.waitForExistence(timeout: 5))
        XCTAssertEqual(list.cells.count, 1, "Only favorited note should be visible")
        XCTAssertTrue(noteB.waitForExistence(timeout: 5), "Note 'B' should be visible")

        // Выключить фильтр
        filterButton.tap()

        // Проверить: в списке 3 ячейки
        XCTAssertEqual(list.cells.count, 3, "All notes should be visible after disabling filter")
    }
}
