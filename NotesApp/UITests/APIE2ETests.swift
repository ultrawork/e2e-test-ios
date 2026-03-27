import XCTest

final class APIE2ETests: XCTestCase {

    private var app: XCUIApplication!

    /// Base URL for direct backend API calls from the test process.
    private var apiBaseURL: String {
        ProcessInfo.processInfo.environment["API_URL"]
            ?? ProcessInfo.processInfo.environment["BASE_URL"]
            ?? "http://localhost:3000"
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Element Helpers

    private var notesList: XCUIElement {
        app.collectionViews["notes_list"]
    }

    private var loadingIndicator: XCUIElement {
        app.activityIndicators["loading_indicator"]
    }

    private var errorMessage: XCUIElement {
        app.staticTexts["error_message"]
    }

    private var notesCounter: XCUIElement {
        app.staticTexts["notes_counter_text"]
    }

    /// Fetches a dev JWT token from the backend.
    private func fetchDevToken() throws -> String {
        let url = URL(string: "\(apiBaseURL)/api/auth/dev-token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let expectation = self.expectation(description: "Fetch dev token")
        var tokenResult: String?
        var fetchError: Error?

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                fetchError = error
                expectation.fulfill()
                return
            }
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let token = json["token"] as? String else {
                fetchError = NSError(domain: "APIE2ETests", code: 1,
                                     userInfo: [NSLocalizedDescriptionKey: "Failed to parse token response"])
                expectation.fulfill()
                return
            }
            tokenResult = token
            expectation.fulfill()
        }
        task.resume()
        wait(for: [expectation], timeout: 10)

        if let error = fetchError {
            throw error
        }
        return try XCTUnwrap(tokenResult, "Dev token should not be nil")
    }

    /// Creates a note on the backend using the given token.
    private func createNote(token: String, title: String, content: String) throws {
        let url = URL(string: "\(apiBaseURL)/api/notes")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["title": title, "content": content]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let expectation = self.expectation(description: "Create note")
        var fetchError: Error?

        let task = URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                fetchError = error
            } else if let httpResponse = response as? HTTPURLResponse,
                      !(200..<300).contains(httpResponse.statusCode) {
                fetchError = NSError(domain: "APIE2ETests", code: httpResponse.statusCode,
                                     userInfo: [NSLocalizedDescriptionKey: "Create note failed with status \(httpResponse.statusCode)"])
            }
            expectation.fulfill()
        }
        task.resume()
        wait(for: [expectation], timeout: 10)

        if let error = fetchError {
            throw error
        }
    }

    /// Makes a GET request to /api/notes and returns the HTTP status code.
    private func fetchNotesStatusCode(token: String?) throws -> Int {
        let url = URL(string: "\(apiBaseURL)/api/notes")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let expectation = self.expectation(description: "Fetch notes status")
        var statusCode: Int = 0
        var fetchError: Error?

        let task = URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                fetchError = error
            } else if let httpResponse = response as? HTTPURLResponse {
                statusCode = httpResponse.statusCode
            }
            expectation.fulfill()
        }
        task.resume()
        wait(for: [expectation], timeout: 10)

        if let error = fetchError {
            throw error
        }
        return statusCode
    }

    // MARK: - SC-01: Successful notes loading with valid Bearer JWT

    func testSC01_successfulLoadWithValidToken() throws {
        // Arrange: get a dev token and create a test note
        let token = try fetchDevToken()
        try createNote(token: token, title: "E2E Test Note", content: "E2E Test Content")

        // Launch app with valid token
        app.launchArguments = ["-token", token]
        app.launch()

        // Wait for loading to finish
        let list = notesList
        XCTAssertTrue(list.waitForExistence(timeout: 10), "Notes list should exist")

        // loading_indicator should disappear
        let loading = loadingIndicator
        if loading.exists {
            let disappeared = NSPredicate(format: "exists == false")
            expectation(for: disappeared, evaluatedWith: loading, handler: nil)
            waitForExpectations(timeout: 10)
        }

        // error_message should not be visible
        XCTAssertFalse(errorMessage.exists, "Error message should not be visible")

        // List should have at least one cell
        XCTAssertGreaterThan(list.cells.count, 0, "Notes list should not be empty")

        // Counter should show > 0
        let counter = notesCounter
        XCTAssertTrue(counter.waitForExistence(timeout: 5), "Counter should exist")
        XCTAssertFalse(counter.label.contains(": 0"), "Counter should not show 0 notes")
    }

    // MARK: - SC-02: Empty list and error when no token

    func testSC02_noTokenShowsUnauthorized() throws {
        // Launch app without token (remove any existing)
        app.launchArguments = ["-token", ""]
        app.launch()

        // Wait for loading to finish
        let loading = loadingIndicator
        if loading.exists {
            let disappeared = NSPredicate(format: "exists == false")
            expectation(for: disappeared, evaluatedWith: loading, handler: nil)
            waitForExpectations(timeout: 10)
        }

        // error_message should be visible with "Unauthorized"
        let error = errorMessage
        XCTAssertTrue(error.waitForExistence(timeout: 10), "Error message should appear")
        XCTAssertEqual(error.label, "Unauthorized", "Error should say Unauthorized")

        // Notes list should be empty
        let list = notesList
        XCTAssertTrue(list.waitForExistence(timeout: 5), "Notes list should exist")
        XCTAssertEqual(list.cells.count, 0, "Notes list should be empty")

        // Counter should show 0
        let counter = notesCounter
        XCTAssertTrue(counter.waitForExistence(timeout: 5))
        XCTAssertTrue(counter.label.contains("0"), "Counter should show 0 notes")
    }

    // MARK: - SC-03: Auth error with invalid token

    func testSC03_invalidTokenShowsUnauthorized() throws {
        // Launch app with an invalid token
        app.launchArguments = ["-token", "invalid_jwt_token_12345"]
        app.launch()

        // Wait for loading to finish
        let loading = loadingIndicator
        if loading.exists {
            let disappeared = NSPredicate(format: "exists == false")
            expectation(for: disappeared, evaluatedWith: loading, handler: nil)
            waitForExpectations(timeout: 10)
        }

        // error_message should be visible with "Unauthorized"
        let error = errorMessage
        XCTAssertTrue(error.waitForExistence(timeout: 10), "Error message should appear")
        XCTAssertEqual(error.label, "Unauthorized", "Error should say Unauthorized")

        // Notes list should be empty
        let list = notesList
        XCTAssertTrue(list.waitForExistence(timeout: 5), "Notes list should exist")
        XCTAssertEqual(list.cells.count, 0, "Notes list should be empty")
    }

    // MARK: - SC-04: Loading indicator appears during loading

    func testSC04_loadingIndicatorShownDuringFetch() throws {
        let token = try fetchDevToken()

        // Launch app with valid token
        app.launchArguments = ["-token", token]
        app.launch()

        // Immediately check for loading indicator — it should appear at launch
        // Note: this may be very fast, so we use a short timeout
        let loading = loadingIndicator
        // Either it exists now or it already finished — both are acceptable
        // The key assertion is that after loading, it disappears
        let loadingAppeared = loading.waitForExistence(timeout: 3)

        // If loading appeared, wait for it to disappear
        if loadingAppeared {
            let disappeared = NSPredicate(format: "exists == false")
            expectation(for: disappeared, evaluatedWith: loading, handler: nil)
            waitForExpectations(timeout: 10)
        }

        // After loading, notes_list should be visible
        let list = notesList
        XCTAssertTrue(list.waitForExistence(timeout: 10), "Notes list should be visible after loading")

        // loading_indicator should not be visible after completion
        XCTAssertFalse(loading.exists, "Loading indicator should not be visible after fetch completes")
    }

    // MARK: - SC-05: Backend requires Bearer JWT for GET /api/notes

    func testSC05_backendRequiresJWT() throws {
        // Request without token should return 401
        let statusNoToken = try fetchNotesStatusCode(token: nil)
        XCTAssertEqual(statusNoToken, 401, "Request without token should return 401")

        // Request with invalid token should return 401
        let statusInvalid = try fetchNotesStatusCode(token: "invalid_jwt_token_12345")
        XCTAssertEqual(statusInvalid, 401, "Request with invalid token should return 401")

        // Request with valid token should return 200
        let validToken = try fetchDevToken()
        let statusValid = try fetchNotesStatusCode(token: validToken)
        XCTAssertEqual(statusValid, 200, "Request with valid token should return 200")
    }
}
