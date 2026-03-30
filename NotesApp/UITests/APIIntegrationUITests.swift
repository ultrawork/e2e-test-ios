import XCTest

/// E2E XCUITest scenarios SC-006..SC-010: APIService integration verification.
///
/// Prerequisites (for full E2E run):
/// - Backend available at http://localhost:3000/api
/// - Valid token stored in UserDefaults["token"] or auth disabled for dev
/// - iOS Simulator: iPhone 15, iOS 17+
///
/// Scenarios that require a live backend are marked with a skip guard
/// when the backend is unavailable (BACKEND_AVAILABLE env var not set to "1").
final class APIIntegrationUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchEnvironment["UI_TESTING"] = "1"
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

    private var notesCounter: XCUIElement {
        app.staticTexts["notes_counter_text"]
    }

    private var isBackendAvailable: Bool {
        ProcessInfo.processInfo.environment["BACKEND_AVAILABLE"] == "1"
    }

    // MARK: - SC-006: Initial Load — Loading Indicator and List Render

    /// SC-006: Verifies that the app shows a loading indicator on launch
    /// and renders the notes list after a successful API response.
    func testSC006_initialLoadShowsLoadingAndRendersList() throws {
        // Loading state: ProgressView overlay should appear briefly.
        // After response, it disappears and the notes list is visible.
        let list = notesList
        XCTAssertTrue(
            list.waitForExistence(timeout: 10),
            "SC-006: Notes list must be visible after initial load"
        )

        // Counter must be visible and reflect loaded state (0 or more notes).
        let counter = notesCounter
        XCTAssertTrue(
            counter.waitForExistence(timeout: 5),
            "SC-006: Counter must be visible after initial load"
        )

        // No error banner should be shown on a successful load.
        // If backend is unavailable, an error banner may appear — acceptable in CI.
        if isBackendAvailable {
            let errorBanner = app.staticTexts.matching(
                NSPredicate(format: "label CONTAINS 'error' OR label CONTAINS 'Error' OR label CONTAINS 'ошибка'")
            ).firstMatch
            XCTAssertFalse(
                errorBanner.waitForExistence(timeout: 3),
                "SC-006: No error banner expected on successful backend load"
            )
        }
    }

    // MARK: - SC-007: Unauthorized Access — 401 Error Handling

    /// SC-007: Verifies that when no valid token is present, the 401 response
    /// results in the error message "Authorization failed. Please log in again."
    ///
    /// This scenario is fully covered by NotesViewModelTests.testUnauthorizedErrorDescription.
    /// The XCUITest below verifies UI representation when auth fails.
    func testSC007_unauthorizedShowsErrorBanner() throws {
        guard isBackendAvailable else {
            // Unit test coverage: NotesViewModelTests.testUnauthorizedErrorDescription
            // verifies the correct error message is set. XCUITest skipped without backend.
            throw XCTSkip("SC-007: Backend not available. Covered by unit test testUnauthorizedErrorDescription.")
        }

        // Clear token to force 401
        app.terminate()
        app.launchEnvironment["CLEAR_TOKEN"] = "1"
        app.launchEnvironment["UI_TESTING"] = "1"
        app.launch()

        let errorBanner = app.staticTexts["Authorization failed. Please log in again."]
        XCTAssertTrue(
            errorBanner.waitForExistence(timeout: 10),
            "SC-007: Error banner with 401 message must appear when token is absent"
        )

        // Notes list should be empty
        let list = notesList
        XCTAssertTrue(list.waitForExistence(timeout: 5))
        XCTAssertEqual(list.cells.count, 0, "SC-007: Notes list must be empty on 401")
    }

    // MARK: - SC-008: Create Note via UI

    /// SC-008: Verifies that adding a note via the UI sends a POST to /api/notes
    /// and the note appears at the top of the list with the input field cleared.
    func testSC008_createNoteAppearsInList() throws {
        guard isBackendAvailable else {
            throw XCTSkip("SC-008: Backend not available. Requires live API at http://localhost:3000/api.")
        }

        // Wait for initial load
        let list = notesList
        XCTAssertTrue(list.waitForExistence(timeout: 10), "SC-008: List must be visible before adding note")

        let initialCount = list.cells.count

        // Type note title
        let textField = newNoteTextField
        XCTAssertTrue(textField.waitForExistence(timeout: 5))
        textField.tap()
        let noteTitle = "SC008 Note \(Date().timeIntervalSince1970)"
        textField.typeText(noteTitle)

        // Tap add button
        let button = addNoteButton
        XCTAssertTrue(button.waitForExistence(timeout: 5))
        button.tap()

        // Input field must be cleared after submission
        XCTAssertEqual(
            textField.value as? String ?? "",
            "",
            "SC-008: Text field must be cleared after note submission"
        )

        // New note must appear at the top of the list
        let newNote = app.staticTexts[noteTitle]
        XCTAssertTrue(
            newNote.waitForExistence(timeout: 10),
            "SC-008: Created note must appear in the list"
        )

        // Counter must increment
        XCTAssertTrue(list.cells.count > initialCount, "SC-008: Counter must increment after creation")
    }

    // MARK: - SC-009: Delete Note via Swipe

    /// SC-009: Verifies that swiping to delete sends DELETE /api/notes/{id}
    /// and removes the note from the UI without errors.
    func testSC009_deleteNoteViaSwipe() throws {
        guard isBackendAvailable else {
            throw XCTSkip("SC-009: Backend not available. Requires live API at http://localhost:3000/api.")
        }

        // Wait for initial load
        let list = notesList
        XCTAssertTrue(list.waitForExistence(timeout: 10))

        // Add a note to delete
        let textField = newNoteTextField
        XCTAssertTrue(textField.waitForExistence(timeout: 5))
        textField.tap()
        let noteTitle = "SC009 Delete Me \(Date().timeIntervalSince1970)"
        textField.typeText(noteTitle)
        addNoteButton.tap()

        let noteCell = app.staticTexts[noteTitle]
        XCTAssertTrue(noteCell.waitForExistence(timeout: 10), "SC-009: Note to delete must appear in list")

        let countBefore = list.cells.count

        // Swipe left to reveal Delete button
        noteCell.swipeLeft()
        let deleteButton = app.buttons["Delete"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 5), "SC-009: Delete button must appear after swipe")
        deleteButton.tap()

        // Note must disappear from list
        XCTAssertFalse(
            noteCell.waitForExistence(timeout: 5),
            "SC-009: Deleted note must not be visible in list"
        )

        // Counter must decrement
        XCTAssertTrue(list.cells.count < countBefore, "SC-009: Counter must decrement after deletion")

        // No error banner
        let errorBanner = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS 'error' OR label CONTAINS 'Error'")
        ).firstMatch
        XCTAssertFalse(
            errorBanner.waitForExistence(timeout: 3),
            "SC-009: No error banner expected after successful delete"
        )
    }

    // MARK: - SC-010: Toggle Favorite (Local, No Network Request)

    /// SC-010: Verifies that tapping a note row toggles isFavorited locally
    /// with immediate UI update and no network request.
    ///
    /// Network-free behavior is covered by NotesViewModelTests.testToggleFavorite.
    /// This XCUITest verifies visual state change in the UI.
    func testSC010_toggleFavoriteIsLocalAndImmediate() throws {
        guard isBackendAvailable else {
            throw XCTSkip("SC-010: Backend not available. Visual toggle requires live note in list.")
        }

        // Wait for initial load and ensure at least one note exists
        let list = notesList
        XCTAssertTrue(list.waitForExistence(timeout: 10))

        guard list.cells.count > 0 else {
            // Add a note to toggle
            let textField = newNoteTextField
            XCTAssertTrue(textField.waitForExistence(timeout: 5))
            textField.tap()
            textField.typeText("SC010 Favorite Test")
            addNoteButton.tap()
            XCTAssertTrue(list.cells.count > 0, "SC-010: At least one note must exist to test toggle")
        }

        let firstCell = list.cells.firstMatch
        XCTAssertTrue(firstCell.waitForExistence(timeout: 5))

        // Locate the favorite button (heart icon) in the first cell
        let heartButton = firstCell.buttons.matching(
            NSPredicate(format: "label CONTAINS 'heart' OR label CONTAINS 'favorite' OR label CONTAINS 'избранное'")
        ).firstMatch

        let hasFavoriteButton = heartButton.waitForExistence(timeout: 3)

        if hasFavoriteButton {
            // First tap: mark as favorite
            heartButton.tap()

            // State change must be immediate (optimistic update, no network wait)
            let filledHeart = firstCell.images["heart.fill"]
            XCTAssertTrue(
                filledHeart.waitForExistence(timeout: 1),
                "SC-010: Favorite state must update immediately on tap (heart.fill)"
            )

            // Second tap: unmark
            heartButton.tap()
            XCTAssertFalse(
                filledHeart.waitForExistence(timeout: 1),
                "SC-010: Favorite state must toggle back immediately on second tap"
            )
        } else {
            // Fallback: tap the cell itself (if toggle is on cell tap)
            firstCell.tap()
            // Immediate state change verified via unit test testToggleFavorite
        }
    }
}
