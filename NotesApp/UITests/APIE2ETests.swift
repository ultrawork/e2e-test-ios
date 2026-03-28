import XCTest

final class APIE2ETests: XCTestCase {

    private var baseURL: String!

    override func setUpWithError() throws {
        continueAfterFailure = false
        baseURL = ProcessInfo.processInfo.environment["BASE_URL"] ?? "http://localhost:4000"
    }

    // MARK: - Helpers

    private func performRequest(
        path: String,
        method: String = "GET",
        headers: [String: String] = [:],
        body: Data? = nil
    ) throws -> (Data, HTTPURLResponse) {
        guard let url = URL(string: "\(baseURL!)\(path)") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        request.httpBody = body

        let expectation = XCTestExpectation(description: "API \(method) \(path)")
        var resultData: Data?
        var resultResponse: HTTPURLResponse?
        var resultError: Error?

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            resultData = data
            resultResponse = response as? HTTPURLResponse
            resultError = error
            expectation.fulfill()
        }
        task.resume()
        wait(for: [expectation], timeout: 30)

        if let error = resultError {
            throw error
        }
        guard let data = resultData, let response = resultResponse else {
            throw URLError(.badServerResponse)
        }
        return (data, response)
    }

    // MARK: - SC-IOS-06: GET /api/notes returns correct JSON array

    func testSC_IOS_06_getNotesReturnsJSONArray() throws {
        let token = ProcessInfo.processInfo.environment["DEV_TOKEN"] ?? "dev_token_placeholder"
        let (data, response) = try performRequest(
            path: "/api/notes",
            headers: ["Authorization": "Bearer \(token)"]
        )

        // HTTP status should be 200
        XCTAssertEqual(response.statusCode, 200, "GET /api/notes should return 200")

        // Body should be a valid JSON array
        let json = try JSONSerialization.jsonObject(with: data, options: [])
        let array = try XCTUnwrap(json as? [[String: Any]], "Response should be a JSON array of objects")

        // Each element should contain "id" (string) and "content" (string) —
        // matching CodingKeys in Note.swift (text = "content")
        for item in array {
            let id = item["id"]
            XCTAssertNotNil(id, "Each note should have an 'id' field")
            XCTAssertTrue(id is String, "Note 'id' should be a string")

            let content = item["content"]
            XCTAssertNotNil(content, "Each note should have a 'content' field (maps to 'text' via CodingKeys)")
            XCTAssertTrue(content is String, "Note 'content' should be a string")
        }
    }

    // MARK: - SC-IOS-07: GET /api/notes without token when JWT enabled returns 401

    func testSC_IOS_07_getNotesWithoutTokenReturns401() throws {
        // Send request WITHOUT Authorization header
        let (_, response) = try performRequest(path: "/api/notes")

        // When JWT_ENABLED=true, server should respond with 401 Unauthorized
        XCTAssertEqual(
            response.statusCode,
            401,
            "GET /api/notes without Authorization header should return 401 when JWT is enabled"
        )
    }
}
