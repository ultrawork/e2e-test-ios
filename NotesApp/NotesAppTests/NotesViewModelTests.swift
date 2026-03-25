import XCTest
@testable import NotesApp

@MainActor
final class NotesViewModelTests: XCTestCase {
    private var sut: NotesViewModel!
    private var session: URLSession!

    override func setUp() {
        super.setUp()
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        session = URLSession(configuration: config)
        let apiService = APIService(session: session)
        sut = NotesViewModel(apiService: apiService)
        UserDefaults.standard.set("test-token", forKey: "jwtToken")
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "jwtToken")
        MockURLProtocol.requestHandler = nil
        sut = nil
        session = nil
        super.tearDown()
    }

    // MARK: - loadNotes

    func testLoadNotesPopulatesArray() async {
        let json = """
        [
            {"id": "1", "title": "A", "content": "B", "created_at": "2025-01-01T00:00:00Z", "updated_at": "2025-01-01T00:00:00Z"}
        ]
        """.data(using: .utf8)!

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, json)
        }

        await sut.loadNotes()

        XCTAssertEqual(sut.notes.count, 1)
        XCTAssertEqual(sut.notes[0].title, "A")
        XCTAssertNil(sut.error)
        XCTAssertFalse(sut.isLoading)
    }

    func testLoadNotesSetsErrorOnFailure() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        await sut.loadNotes()

        XCTAssertNotNil(sut.error)
        XCTAssertTrue(sut.notes.isEmpty)
        XCTAssertFalse(sut.isLoading)
    }

    func testLoadNotesSetsIsLoadingToFalseAfterCompletion() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, "[]".data(using: .utf8)!)
        }

        await sut.loadNotes()

        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - addNote

    func testAddNoteAppendsToArray() async {
        let json = """
        {"id": "10", "title": "New Note", "content": "New Note", "created_at": "2025-01-01T00:00:00Z", "updated_at": "2025-01-01T00:00:00Z"}
        """.data(using: .utf8)!

        MockURLProtocol.requestHandler = { request in
            let body = try JSONSerialization.jsonObject(with: request.httpBody ?? Data()) as? [String: String]
            XCTAssertEqual(body?["title"], "New Note")
            XCTAssertEqual(body?["content"], "New Note")
            let response = HTTPURLResponse(url: request.url!, statusCode: 201, httpVersion: nil, headerFields: nil)!
            return (response, json)
        }

        await sut.addNote(title: "New Note")

        XCTAssertEqual(sut.notes.count, 1)
        XCTAssertEqual(sut.notes[0].id, "10")
        XCTAssertEqual(sut.notes[0].title, "New Note")
        XCTAssertNil(sut.error)
        XCTAssertFalse(sut.isLoading)
    }

    func testAddNoteSetsErrorOnFailure() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        await sut.addNote(title: "Fail")

        XCTAssertTrue(sut.notes.isEmpty)
        XCTAssertNotNil(sut.error)
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - deleteNote

    func testDeleteNoteRemovesFromArray() async {
        let loadJSON = """
        [
            {"id": "1", "title": "A", "content": "", "created_at": "2025-01-01T00:00:00Z", "updated_at": "2025-01-01T00:00:00Z"},
            {"id": "2", "title": "B", "content": "", "created_at": "2025-01-01T00:00:00Z", "updated_at": "2025-01-01T00:00:00Z"}
        ]
        """.data(using: .utf8)!

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, loadJSON)
        }

        await sut.loadNotes()
        XCTAssertEqual(sut.notes.count, 2)

        MockURLProtocol.requestHandler = { request in
            XCTAssertTrue(request.url?.path.contains("/api/notes/1") ?? false)
            let response = HTTPURLResponse(url: request.url!, statusCode: 204, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        await sut.deleteNote(id: "1")

        XCTAssertEqual(sut.notes.count, 1)
        XCTAssertEqual(sut.notes[0].id, "2")
        XCTAssertNil(sut.error)
        XCTAssertFalse(sut.isLoading)
    }

    func testDeleteNoteSetsErrorOnFailure() async {
        let loadJSON = """
        [{"id": "1", "title": "A", "content": "", "created_at": "2025-01-01T00:00:00Z", "updated_at": "2025-01-01T00:00:00Z"}]
        """.data(using: .utf8)!

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, loadJSON)
        }

        await sut.loadNotes()

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        await sut.deleteNote(id: "1")

        XCTAssertEqual(sut.notes.count, 1, "Note should not be removed on failure")
        XCTAssertNotNil(sut.error)
        XCTAssertFalse(sut.isLoading)
    }
}
