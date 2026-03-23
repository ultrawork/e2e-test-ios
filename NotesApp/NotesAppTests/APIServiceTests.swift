import XCTest
@testable import NotesApp

/// URLProtocol subclass that intercepts network requests for testing.
final class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            XCTFail("No request handler set")
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

final class APIServiceTests: XCTestCase {

    private var service: APIService!
    private var session: URLSession!
    private let baseURL = URL(string: "http://localhost:3000/api")!

    override func setUp() {
        super.setUp()
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        session = URLSession(configuration: config)
        service = APIService(baseURL: baseURL, session: session)
    }

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        service = nil
        session = nil
        super.tearDown()
    }

    // MARK: - fetchNotes

    func testFetchNotesReturnsDecodedNotes() async throws {
        let json = """
        [
            {"id": "1", "title": "Note 1", "content": "Content 1"},
            {"id": "2", "title": "Note 2", "content": "Content 2", "isFavorited": true}
        ]
        """.data(using: .utf8)!

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertTrue(request.url!.absoluteString.contains("/notes"))
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, json)
        }

        let notes = try await service.fetchNotes()

        XCTAssertEqual(notes.count, 2)
        XCTAssertEqual(notes[0].id, "1")
        XCTAssertEqual(notes[0].title, "Note 1")
        XCTAssertEqual(notes[1].isFavorited, true)
    }

    func testFetchNotesReturnsEmptyArrayOn401() async throws {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        let notes = try await service.fetchNotes()

        XCTAssertEqual(notes, [])
    }

    func testFetchNotesSetsAuthorizationHeader() async throws {
        UserDefaults.standard.set("test-token-123", forKey: "token")
        defer { UserDefaults.standard.removeObject(forKey: "token") }

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-token-123")
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, "[]".data(using: .utf8)!)
        }

        _ = try await service.fetchNotes()
    }

    func testFetchNotesNoAuthorizationHeaderWithoutToken() async throws {
        UserDefaults.standard.removeObject(forKey: "token")

        MockURLProtocol.requestHandler = { request in
            XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, "[]".data(using: .utf8)!)
        }

        _ = try await service.fetchNotes()
    }

    // MARK: - createNote

    func testCreateNoteSendsCorrectRequest() async throws {
        let responseJSON = """
        {"id": "new-1", "title": "Test", "content": "Body"}
        """.data(using: .utf8)!

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
            XCTAssertTrue(request.url!.absoluteString.contains("/notes"))

            let body = try! JSONDecoder().decode([String: String].self, from: request.httpBody!)
            XCTAssertEqual(body["title"], "Test")
            XCTAssertEqual(body["content"], "Body")

            let response = HTTPURLResponse(url: request.url!, statusCode: 201, httpVersion: nil, headerFields: nil)!
            return (response, responseJSON)
        }

        let note = try await service.createNote(title: "Test", content: "Body")

        XCTAssertEqual(note.id, "new-1")
        XCTAssertEqual(note.title, "Test")
        XCTAssertEqual(note.content, "Body")
    }

    // MARK: - deleteNote

    func testDeleteNoteSendsDeleteRequest() async throws {
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "DELETE")
            XCTAssertTrue(request.url!.absoluteString.contains("/notes/abc-123"))
            let response = HTTPURLResponse(url: request.url!, statusCode: 204, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        try await service.deleteNote(id: "abc-123")
    }
}
