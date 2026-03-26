import XCTest
@testable import NotesApp

/// Mock URLProtocol для перехвата сетевых запросов в тестах.
final class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
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
    private var session: URLSession!
    private var apiService: APIService!

    override func setUp() {
        super.setUp()
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        session = URLSession(configuration: config)
        apiService = APIService(baseURL: "http://localhost:3000", session: session)
    }

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        UserDefaults.standard.removeObject(forKey: "token")
        session = nil
        apiService = nil
        super.tearDown()
    }

    /// Проверяет, что токен из UserDefaults передаётся в заголовке Authorization.
    func test_fetchNotes_addsBearerToken() async throws {
        let token = "test-token-123"
        UserDefaults.standard.set(token, forKey: "token")

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(
                request.value(forHTTPHeaderField: "Authorization"),
                "Bearer \(token)"
            )
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            let data = try JSONEncoder().encode([Note(id: 1, text: "Test")])
            return (response, data)
        }

        _ = try await apiService.fetchNotes()
    }

    /// Проверяет, что при HTTP 401 выбрасывается APIError.unauthorized.
    func test_fetchNotes_401_throwsUnauthorized() async {
        UserDefaults.standard.set("some-token", forKey: "token")

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 401,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        do {
            _ = try await apiService.fetchNotes()
            XCTFail("Expected APIError.unauthorized")
        } catch {
            guard case APIError.unauthorized = error else {
                return XCTFail("Expected APIError.unauthorized, got \(error)")
            }
        }
    }

    /// Проверяет корректную декодировку массива Note из JSON.
    func test_fetchNotes_decodesNotes() async throws {
        UserDefaults.standard.set("token", forKey: "token")

        let json = """
        [{"id": 1, "text": "First"}, {"id": 2, "text": "Second"}]
        """.data(using: .utf8)!

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, json)
        }

        let notes = try await apiService.fetchNotes()

        XCTAssertEqual(notes.count, 2)
        XCTAssertEqual(notes[0].id, 1)
        XCTAssertEqual(notes[0].text, "First")
        XCTAssertEqual(notes[1].id, 2)
        XCTAssertEqual(notes[1].text, "Second")
    }
}
