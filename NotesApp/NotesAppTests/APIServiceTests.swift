import XCTest
@testable import NotesApp

final class APIServiceTests: XCTestCase {

    // MARK: - URLProtocol stub

    private final class StubURLProtocol: URLProtocol {
        static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

        override class func canInit(with request: URLRequest) -> Bool { true }
        override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

        override func startLoading() {
            guard let handler = Self.requestHandler else {
                client?.urlProtocolDidFinishLoading(self)
                return
            }
            do {
                let (response, data) = try handler(request)
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client?.urlProtocol(self, didLoad: data)
                client?.urlProtocolDidFinishLoading(self)
            } catch {
                client?.urlProtocol(self, didFailWithError: error)
            }
        }

        override func stopLoading() {}
    }

    private var session: URLSession!
    private var sut: APIService!

    override func setUp() {
        super.setUp()
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]
        session = URLSession(configuration: config)
        sut = APIService(session: session)
    }

    override func tearDown() {
        StubURLProtocol.requestHandler = nil
        session = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Request formation

    func testFetchNotesRequestHasCorrectHeaders() async throws {
        UserDefaults.standard.set("test-token-123", forKey: "token")
        defer { UserDefaults.standard.removeObject(forKey: "token") }

        StubURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-token-123")
            XCTAssertTrue(request.url?.absoluteString.hasSuffix("/notes") == true)

            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, "[]".data(using: .utf8)!)
        }

        _ = try await sut.fetchNotes()
    }

    func testCreateNoteRequestHasBody() async throws {
        UserDefaults.standard.set("tok", forKey: "token")
        defer { UserDefaults.standard.removeObject(forKey: "token") }

        let noteJSON = """
        {"id":"1","title":"T","content":"C","createdAt":"2024-01-01T00:00:00Z","updatedAt":"2024-01-01T00:00:00Z"}
        """

        StubURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            let body = request.httpBody.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: String] }
            XCTAssertEqual(body?["title"], "T")
            XCTAssertEqual(body?["content"], "C")

            let response = HTTPURLResponse(url: request.url!, statusCode: 201, httpVersion: nil, headerFields: nil)!
            return (response, noteJSON.data(using: .utf8)!)
        }

        let note = try await sut.createNote(title: "T", content: "C")
        XCTAssertEqual(note.title, "T")
    }

    func testDeleteNoteRequestUsesCorrectPath() async throws {
        UserDefaults.standard.set("tok", forKey: "token")
        defer { UserDefaults.standard.removeObject(forKey: "token") }

        StubURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "DELETE")
            XCTAssertTrue(request.url?.absoluteString.hasSuffix("/notes/abc-123") == true)

            let response = HTTPURLResponse(url: request.url!, statusCode: 204, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        try await sut.deleteNote(id: "abc-123")
    }

    // MARK: - Error mapping

    func testUnauthorizedErrorMapping() async {
        StubURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        do {
            _ = try await sut.fetchNotes()
            XCTFail("Expected unauthorized error")
        } catch let error as APIError {
            if case .unauthorized = error {} else {
                XCTFail("Expected .unauthorized, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testNotFoundErrorMapping() async {
        StubURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 404, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        do {
            try await sut.deleteNote(id: "nonexistent")
            XCTFail("Expected notFound error")
        } catch let error as APIError {
            if case .notFound = error {} else {
                XCTFail("Expected .notFound, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testServerErrorMapping() async {
        StubURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        do {
            _ = try await sut.fetchNotes()
            XCTFail("Expected server error")
        } catch let error as APIError {
            if case .serverError(let code) = error {
                XCTAssertEqual(code, 500)
            } else {
                XCTFail("Expected .serverError, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testDecodingErrorMapping() async {
        StubURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, "not json".data(using: .utf8)!)
        }

        do {
            _ = try await sut.fetchNotes()
            XCTFail("Expected decoding error")
        } catch let error as APIError {
            if case .decodingError = error {} else {
                XCTFail("Expected .decodingError, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testTransportError() async {
        StubURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        do {
            _ = try await sut.fetchNotes()
            XCTFail("Expected transport error")
        } catch let error as APIError {
            if case .transportError = error {} else {
                XCTFail("Expected .transportError, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - Successful decoding

    func testFetchNotesDecodesValidResponse() async throws {
        let json = """
        [{"id":"1","title":"Note 1","content":"Body","createdAt":"2024-01-01T00:00:00Z","updatedAt":"2024-01-02T00:00:00Z","userId":"u1","categories":[{"id":"c1","name":"Work","color":"#ff0000","createdAt":"2024-01-01T00:00:00Z"}]}]
        """
        StubURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, json.data(using: .utf8)!)
        }

        let notes = try await sut.fetchNotes()
        XCTAssertEqual(notes.count, 1)
        XCTAssertEqual(notes[0].id, "1")
        XCTAssertEqual(notes[0].title, "Note 1")
        XCTAssertEqual(notes[0].userId, "u1")
        XCTAssertEqual(notes[0].categories.count, 1)
        XCTAssertEqual(notes[0].categories[0].name, "Work")
        XCTAssertFalse(notes[0].isFavorited)
    }

    func testFetchNotesDecodesWithoutOptionalFields() async throws {
        let json = """
        [{"id":"2","title":"T","content":"C","createdAt":"2024-01-01T00:00:00Z","updatedAt":"2024-01-01T00:00:00Z"}]
        """
        StubURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, json.data(using: .utf8)!)
        }

        let notes = try await sut.fetchNotes()
        XCTAssertEqual(notes.count, 1)
        XCTAssertNil(notes[0].userId)
        XCTAssertTrue(notes[0].categories.isEmpty)
    }
}
