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
        sut = APIService(
            baseURL: URL(string: "https://example.com")!,
            session: session
        )
    }

    override func tearDown() {
        sut = nil
        session = nil
        UserDefaults.standard.removeObject(forKey: "authToken")
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }

    // MARK: - Token from UserDefaults → Authorization header

    func testFetchNotes_withToken_sendsAuthorizationHeader() async throws {
        UserDefaults.standard.set("test-token-123", forKey: "authToken")

        var capturedRequest: URLRequest?
        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            let notes = [NoteDTO(id: "1", title: "Test", content: "Test content")]
            let data = try JSONEncoder().encode(notes)
            return (response, data)
        }

        _ = try await sut.fetchNotes()

        XCTAssertEqual(
            capturedRequest?.value(forHTTPHeaderField: "Authorization"),
            "Bearer test-token-123"
        )
    }

    // MARK: - No token → no Authorization header

    func testFetchNotes_withoutToken_doesNotSendAuthorizationHeader() async throws {
        UserDefaults.standard.removeObject(forKey: "authToken")

        var capturedRequest: URLRequest?
        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            let notes = [NoteDTO(id: "1", title: "Test", content: "Test content")]
            let data = try JSONEncoder().encode(notes)
            return (response, data)
        }

        _ = try await sut.fetchNotes()

        XCTAssertNil(capturedRequest?.value(forHTTPHeaderField: "Authorization"))
    }

    // MARK: - 401 → APIError.unauthorized

    func testFetchNotes_401Response_throwsUnauthorized() async {
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
            _ = try await sut.fetchNotes()
            XCTFail("Expected APIError.unauthorized to be thrown")
        } catch let error as APIError {
            XCTAssertEqual(error, .unauthorized)
            XCTAssertEqual(error.errorDescription, "Unauthorized")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
