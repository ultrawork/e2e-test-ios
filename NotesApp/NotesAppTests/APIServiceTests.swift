import XCTest
@testable import NotesApp

final class APIServiceTests: XCTestCase {
    private var sut: APIService!
    private var session: URLSession!

    override func setUp() {
        super.setUp()
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        session = URLSession(configuration: config)
        sut = APIService(session: session)
        UserDefaults.standard.set("test-token", forKey: "jwtToken")
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "jwtToken")
        MockURLProtocol.requestHandler = nil
        sut = nil
        session = nil
        super.tearDown()
    }

    // MARK: - fetchNotes

    func testFetchNotesReturnsNotes() async throws {
        let json = """
        [
            {"id": "1", "title": "Note 1", "content": "Content 1", "created_at": "2025-01-01T00:00:00Z", "updated_at": "2025-01-01T00:00:00Z"},
            {"id": "2", "title": "Note 2", "content": "Content 2", "created_at": "2025-01-02T00:00:00Z", "updated_at": "2025-01-02T00:00:00Z"}
        ]
        """.data(using: .utf8)!

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.path, "/api/notes")
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertTrue(request.value(forHTTPHeaderField: "Authorization")?.starts(with: "Bearer ") ?? false)
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, json)
        }

        let notes = try await sut.fetchNotes()
        XCTAssertEqual(notes.count, 2)
        XCTAssertEqual(notes[0].id, "1")
        XCTAssertEqual(notes[0].title, "Note 1")
        XCTAssertEqual(notes[1].id, "2")
        XCTAssertEqual(notes[1].content, "Content 2")
    }

    func testFetchNotesReturnsEmptyArray() async throws {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, "[]".data(using: .utf8)!)
        }

        let notes = try await sut.fetchNotes()
        XCTAssertTrue(notes.isEmpty)
    }

    // MARK: - createNote

    func testCreateNoteSendsCorrectRequest() async throws {
        let responseJSON = """
        {"id": "3", "title": "New", "content": "Body", "created_at": "2025-01-03T00:00:00Z", "updated_at": "2025-01-03T00:00:00Z"}
        """.data(using: .utf8)!

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.path, "/api/notes")
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")

            let body = try JSONSerialization.jsonObject(with: request.httpBody ?? Data()) as? [String: String]
            XCTAssertEqual(body?["title"], "New")
            XCTAssertEqual(body?["content"], "Body")

            let response = HTTPURLResponse(url: request.url!, statusCode: 201, httpVersion: nil, headerFields: nil)!
            return (response, responseJSON)
        }

        let note = try await sut.createNote(title: "New", content: "Body")
        XCTAssertEqual(note.id, "3")
        XCTAssertEqual(note.title, "New")
        XCTAssertEqual(note.content, "Body")
    }

    // MARK: - deleteNote

    func testDeleteNoteSendsCorrectRequest() async throws {
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.path, "/api/notes/42")
            XCTAssertEqual(request.httpMethod, "DELETE")
            let response = HTTPURLResponse(url: request.url!, statusCode: 204, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        try await sut.deleteNote(id: "42")
    }

    // MARK: - Authorization header

    func testRequestIncludesBearerToken() async throws {
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-token")
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, "[]".data(using: .utf8)!)
        }

        _ = try await sut.fetchNotes()
    }

    // MARK: - Error handling

    func testUnauthorizedThrowsAPIError() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        do {
            _ = try await sut.fetchNotes()
            XCTFail("Expected unauthorized error")
        } catch let error as APIError {
            if case .unauthorized = error {
                // Expected
            } else {
                XCTFail("Expected .unauthorized, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testBadResponseThrowsAPIError() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        do {
            _ = try await sut.fetchNotes()
            XCTFail("Expected bad response error")
        } catch let error as APIError {
            if case .badResponse(let code) = error {
                XCTAssertEqual(code, 500)
            } else {
                XCTFail("Expected .badResponse, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testDecodingErrorThrowsAPIError() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, "invalid json".data(using: .utf8)!)
        }

        do {
            _ = try await sut.fetchNotes()
            XCTFail("Expected decoding error")
        } catch let error as APIError {
            if case .decodingError = error {
                // Expected
            } else {
                XCTFail("Expected .decodingError, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - ensureToken (dev-token)

    func testEnsureTokenFetchesDevTokenWhenMissing() async throws {
        UserDefaults.standard.removeObject(forKey: "jwtToken")

        var requestPaths: [String] = []

        MockURLProtocol.requestHandler = { request in
            let path = request.url?.path ?? ""
            requestPaths.append(path)

            if path == "/api/auth/dev-token" {
                let tokenJSON = """
                {"token": "dev-token-123"}
                """.data(using: .utf8)!
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return (response, tokenJSON)
            }

            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, "[]".data(using: .utf8)!)
        }

        _ = try await sut.fetchNotes()

        XCTAssertTrue(requestPaths.contains("/api/auth/dev-token"))
        XCTAssertEqual(UserDefaults.standard.string(forKey: "jwtToken"), "dev-token-123")
    }
}
