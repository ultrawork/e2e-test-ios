import XCTest
@testable import NotesApp

// MARK: - MockURLProtocol

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

// MARK: - APIServiceTests

final class APIServiceTests: XCTestCase {
    private var sut: APIService!
    private var session: URLSession!

    override func setUp() {
        super.setUp()
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        session = URLSession(configuration: config)
        sut = APIService(baseURL: URL(string: "http://localhost:3000/api")!, session: session)
    }

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        UserDefaults.standard.removeObject(forKey: "token")
        sut = nil
        session = nil
        super.tearDown()
    }

    /// Verifies that a Bearer token from UserDefaults is sent in the Authorization header.
    func test_fetchNotes_addsBearerToken() async throws {
        UserDefaults.standard.set("test-token-123", forKey: "token")

        var capturedRequest: URLRequest?
        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 200,
                httpVersion: nil, headerFields: nil
            )!
            let data = "[]".data(using: .utf8)!
            return (response, data)
        }

        _ = try await sut.fetchNotes()

        XCTAssertEqual(
            capturedRequest?.value(forHTTPHeaderField: "Authorization"),
            "Bearer test-token-123"
        )
    }

    /// Verifies that a 401 response throws `APIError.unauthorized`.
    func test_fetchNotes_401_throwsUnauthorized() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 401,
                httpVersion: nil, headerFields: nil
            )!
            return (response, Data())
        }

        do {
            _ = try await sut.fetchNotes()
            XCTFail("Expected APIError.unauthorized")
        } catch {
            XCTAssertTrue(error is APIError)
            if case APIError.unauthorized = error {} else {
                XCTFail("Expected .unauthorized, got \(error)")
            }
        }
    }

    /// Verifies that a valid JSON response is decoded into `[Note]`.
    func test_fetchNotes_decodesNotes() async throws {
        let json = """
        [{"id":"1","content":"Hello"}]
        """
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 200,
                httpVersion: nil, headerFields: nil
            )!
            return (response, json.data(using: .utf8)!)
        }

        let notes = try await sut.fetchNotes()

        XCTAssertEqual(notes, [Note(id: "1", text: "Hello")])
    }
}
