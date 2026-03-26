import XCTest
@testable import NotesApp

final class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data?))?

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
            if let data = data {
                client?.urlProtocol(self, didLoad: data)
            }
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

final class APIServiceTests: XCTestCase {

    private var sut: APIService!
    private var session: URLSession!

    override func setUp() {
        super.setUp()
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        session = URLSession(configuration: config)
        sut = APIService(session: session)
        UserDefaults.standard.set("test-token-123", forKey: "jwtToken")
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "jwtToken")
        MockURLProtocol.requestHandler = nil
        sut = nil
        session = nil
        super.tearDown()
    }

    // MARK: - fetchNotes

    func testFetchNotes_returns401_throwsUnauthorized() async {
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-token-123")
            let response = HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!
            return (response, Data("{\"error\":\"Unauthorized\"}".utf8))
        }

        do {
            _ = try await sut.fetchNotes()
            XCTFail("Expected unauthorized error")
        } catch let error as APIError {
            XCTAssertEqual(error, .unauthorized)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testFetchNotes_returns200_decodesNotes() async throws {
        let json = """
        [{"id":"1","title":"Test","content":"Body","userId":"u1","createdAt":"2024-01-01","updatedAt":"2024-01-01"}]
        """
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertTrue(request.url!.path.hasSuffix("/api/notes"))
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data(json.utf8))
        }

        let notes = try await sut.fetchNotes()
        XCTAssertEqual(notes.count, 1)
        XCTAssertEqual(notes.first?.id, "1")
        XCTAssertEqual(notes.first?.title, "Test")
        XCTAssertEqual(notes.first?.text, "Test")
    }

    // MARK: - createNote

    func testCreateNote_returns401_throwsUnauthorized() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!
            return (response, nil)
        }

        do {
            _ = try await sut.createNote(title: "T", content: "C")
            XCTFail("Expected unauthorized error")
        } catch let error as APIError {
            XCTAssertEqual(error, .unauthorized)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testCreateNote_returns201_returnsNote() async throws {
        let json = """
        {"id":"2","title":"New","content":"Content"}
        """
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertTrue(request.url!.path.hasSuffix("/api/notes"))
            let response = HTTPURLResponse(url: request.url!, statusCode: 201, httpVersion: nil, headerFields: nil)!
            return (response, Data(json.utf8))
        }

        let note = try await sut.createNote(title: "New", content: "Content")
        XCTAssertEqual(note.id, "2")
        XCTAssertEqual(note.title, "New")
    }

    // MARK: - deleteNote

    func testDeleteNote_returns401_throwsUnauthorized() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!
            return (response, nil)
        }

        do {
            try await sut.deleteNote(id: "1")
            XCTFail("Expected unauthorized error")
        } catch let error as APIError {
            XCTAssertEqual(error, .unauthorized)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testDeleteNote_returns204_succeeds() async throws {
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "DELETE")
            XCTAssertTrue(request.url!.path.hasSuffix("/api/notes/1"))
            let response = HTTPURLResponse(url: request.url!, statusCode: 204, httpVersion: nil, headerFields: nil)!
            return (response, nil)
        }

        try await sut.deleteNote(id: "1")
    }

    // MARK: - Authorization header

    func testFetchNotes_noToken_noAuthorizationHeader() async {
        UserDefaults.standard.removeObject(forKey: "jwtToken")
        MockURLProtocol.requestHandler = { request in
            XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data("[]".utf8))
        }

        do {
            _ = try await sut.fetchNotes()
        } catch {
            // Acceptable — we just need to verify the header
        }
    }
}
