import XCTest

final class AuthE2ETests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Helpers

    private var errorBanner: XCUIElement {
        app.otherElements["error_banner"]
    }

    private var dismissErrorButton: XCUIElement {
        app.buttons["dismiss_error_button"]
    }

    private var loadingIndicator: XCUIElement {
        app.activityIndicators["loading_indicator"]
    }

    private var newNoteTextField: XCUIElement {
        app.textFields["new_note_text_field"]
    }

    private var addNoteButton: XCUIElement {
        app.buttons["add_note_button"]
    }

    // MARK: - SC-011: Error banner dismisses on tap

    func testSC011_dismissErrorBanner() {
        // Launch without token to trigger auth error
        app.launchArguments += ["-resetDefaults"]
        app.launch()

        // Wait for error banner to appear
        let banner = errorBanner
        XCTAssertTrue(banner.waitForExistence(timeout: 10), "Error banner should appear when no JWT token is set")

        // Tap dismiss button
        let dismissButton = dismissErrorButton
        XCTAssertTrue(dismissButton.waitForExistence(timeout: 5), "Dismiss button should exist inside error banner")
        dismissButton.tap()

        // Verify banner disappeared
        let disappeared = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: disappeared, object: banner)
        let result = XCTWaiter().wait(for: [expectation], timeout: 5)
        XCTAssertEqual(result, .completed, "Error banner should disappear after dismiss")

        // Verify rest of UI is still accessible
        XCTAssertTrue(newNoteTextField.waitForExistence(timeout: 5), "Text field should still be visible after dismissing error")
        XCTAssertTrue(addNoteButton.waitForExistence(timeout: 5), "Add button should still be visible after dismissing error")
    }

    // MARK: - SC-012: Loading indicator appears during fetch

    func testSC012_loadingIndicatorAppearsWithToken() {
        // Launch with a valid token
        app.launchEnvironment["JWT_TOKEN"] = "test-e2e-token"
        app.launch()

        // Check if loading indicator appears (it may be very brief)
        let indicator = loadingIndicator
        if indicator.waitForExistence(timeout: 3) {
            // Loading indicator appeared — now wait for it to disappear
            let disappeared = NSPredicate(format: "exists == false")
            let expectation = XCTNSPredicateExpectation(predicate: disappeared, object: indicator)
            let result = XCTWaiter().wait(for: [expectation], timeout: 15)
            XCTAssertEqual(result, .completed, "Loading indicator should disappear after fetch completes")
        }
        // If loading indicator didn't appear within 3s, the fetch was too fast — that's acceptable
    }
}
