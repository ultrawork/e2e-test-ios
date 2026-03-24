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
        UserDefaults.standard.removeObject(forKey: "authToken")
    }

    override func tearDown() {
        sut = nil
        session = nil
        MockURLProtocol.requestHandler = nil
        UserDefaults.standard.removeObject(forKey: "authToken")
        super.tearDown()
    }

    // MARK: - fetchNotes

    func testFetchNotesReturnsDecodedNotes() async throws {
        let json = """
        [
            {
                "id": "1",
                "title": "Test Note",
                "content": "Body",
                "userId": "u1",
                "createdAt": "2024-01-01T00:00:00Z",
                "updatedAt": "2024-01-01T00:00:00Z",
                "categories": []
            }
        ]
        """.data(using: .utf8)!

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertTrue(request.url!.path.hasSuffix("/api/notes"))
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 200,
                httpVersion: nil, headerFields: nil)!
            return (response, json)
        }

        let notes = try await sut.fetchNotes()
        XCTAssertEqual(notes.count, 1)
        XCTAssertEqual(notes.first?.id, "1")
        XCTAssertEqual(notes.first?.title, "Test Note")
    }

    func testFetchNotesThrowsUnauthorizedOn401() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 401,
                httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        do {
            _ = try await sut.fetchNotes()
            XCTFail("Expected unauthorized error")
        } catch let error as APIError {
            XCTAssertEqual(error, .unauthorized)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testFetchNotesSendsAuthorizationHeader() async throws {
        UserDefaults.standard.set("test-token-123", forKey: "authToken")

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(
                request.value(forHTTPHeaderField: "Authorization"),
                "Bearer test-token-123"
            )
            let json = "[]".data(using: .utf8)!
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 200,
                httpVersion: nil, headerFields: nil)!
            return (response, json)
        }

        _ = try await sut.fetchNotes()
    }

    func testFetchNotesThrowsDecodingErrorOnInvalidJSON() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 200,
                httpVersion: nil, headerFields: nil)!
            return (response, "not json".data(using: .utf8)!)
        }

        do {
            _ = try await sut.fetchNotes()
            XCTFail("Expected decoding error")
        } catch let error as APIError {
            XCTAssertEqual(error, .decodingError)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - createNote

    func testCreateNoteReturnsDecodedNote() async throws {
        let json = """
        {
            "id": "new-1",
            "title": "Created",
            "content": "Body",
            "userId": null,
            "createdAt": "2024-01-01T00:00:00Z",
            "updatedAt": "2024-01-01T00:00:00Z",
            "categories": []
        }
        """.data(using: .utf8)!

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertTrue(request.url!.path.hasSuffix("/api/notes"))
            XCTAssertNotNil(request.httpBody)
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 201,
                httpVersion: nil, headerFields: nil)!
            return (response, json)
        }

        let note = try await sut.createNote(title: "Created", content: "Body")
        XCTAssertEqual(note.id, "new-1")
        XCTAssertEqual(note.title, "Created")
    }

    func testCreateNoteSendsCorrectBody() async throws {
        let json = """
        {
            "id": "1", "title": "T", "content": "C", "userId": null,
            "createdAt": "2024-01-01T00:00:00Z", "updatedAt": "2024-01-01T00:00:00Z",
            "categories": []
        }
        """.data(using: .utf8)!

        MockURLProtocol.requestHandler = { request in
            let body = try! JSONSerialization.jsonObject(with: request.httpBody!) as! [String: String]
            XCTAssertEqual(body["title"], "My Title")
            XCTAssertEqual(body["content"], "My Content")
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 200,
                httpVersion: nil, headerFields: nil)!
            return (response, json)
        }

        _ = try await sut.createNote(title: "My Title", content: "My Content")
    }

    // MARK: - deleteNote

    func testDeleteNoteSucceeds() async throws {
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "DELETE")
            XCTAssertTrue(request.url!.path.hasSuffix("/api/notes/note-42"))
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 200,
                httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        try await sut.deleteNote(id: "note-42")
    }

    func testDeleteNoteThrowsNotFoundOn404() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 404,
                httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        do {
            try await sut.deleteNote(id: "missing")
            XCTFail("Expected notFound error")
        } catch let error as APIError {
            XCTAssertEqual(error, .notFound)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - fetchDevToken

    func testFetchDevTokenStoresTokenInUserDefaults() async throws {
        let json = """
        {"token": "dev-token-abc"}
        """.data(using: .utf8)!

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertTrue(request.url!.path.hasSuffix("/api/auth/dev-token"))
            XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 200,
                httpVersion: nil, headerFields: nil)!
            return (response, json)
        }

        try await sut.fetchDevToken()
        XCTAssertEqual(
            UserDefaults.standard.string(forKey: "authToken"),
            "dev-token-abc"
        )
    }

    func testFetchDevTokenThrowsDecodingErrorOnBadResponse() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 200,
                httpVersion: nil, headerFields: nil)!
            return (response, "{}".data(using: .utf8)!)
        }

        do {
            try await sut.fetchDevToken()
            XCTFail("Expected decoding error")
        } catch let error as APIError {
            XCTAssertEqual(error, .decodingError)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testFetchDevTokenDoesNotSendAuthHeader() async throws {
        let json = """
        {"token": "tok"}
        """.data(using: .utf8)!

        UserDefaults.standard.set("existing-token", forKey: "authToken")

        MockURLProtocol.requestHandler = { request in
            XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 200,
                httpVersion: nil, headerFields: nil)!
            return (response, json)
        }

        try await sut.fetchDevToken()
    }

    // MARK: - Server errors

    func testServerErrorMapsStatusCode() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 500,
                httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        do {
            _ = try await sut.fetchNotes()
            XCTFail("Expected server error")
        } catch let error as APIError {
            if case .serverError(let code, _) = error {
                XCTAssertEqual(code, 500)
            } else {
                XCTFail("Expected serverError, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - Transport error

    func testTransportErrorOnNetworkFailure() async {
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        do {
            _ = try await sut.fetchNotes()
            XCTFail("Expected transport error")
        } catch let error as APIError {
            XCTAssertEqual(error, .transportError)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
}
