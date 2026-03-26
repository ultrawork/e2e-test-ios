import XCTest
@testable import NotesApp

// MARK: - Mock API Service

private final class MockAPIService: APIServiceProtocol {
    var fetchNotesResult: Result<[Note], Error> = .success([])
    var createNoteResult: Result<Note, Error> = .success(MockAPIService.sampleNote())
    var deleteNoteResult: Result<Void, Error> = .success(())

    var fetchNotesCalled = false
    var createNoteTitle: String?
    var createNoteContent: String?
    var deleteNoteId: String?

    func fetchNotes() async throws -> [Note] {
        fetchNotesCalled = true
        return try fetchNotesResult.get()
    }

    func createNote(title: String, content: String) async throws -> Note {
        createNoteTitle = title
        createNoteContent = content
        return try createNoteResult.get()
    }

    func deleteNote(id: String) async throws {
        deleteNoteId = id
        try deleteNoteResult.get()
    }

    static func sampleNote(
        id: String = "1",
        title: String = "Test",
        content: String = "Body"
    ) -> Note {
        Note(
            id: id,
            title: title,
            content: content,
            createdAt: Date(),
            updatedAt: Date(),
            userId: nil,
            categories: []
        )
    }
}

// MARK: - Tests

@MainActor
final class NotesViewModelTests: XCTestCase {

    private var mockService: MockAPIService!
    private var sut: NotesViewModel!

    override func setUp() {
        super.setUp()
        mockService = MockAPIService()
        sut = NotesViewModel(apiService: mockService)
    }

    override func tearDown() {
        sut = nil
        mockService = nil
        super.tearDown()
    }

    // MARK: - fetchNotes

    func testFetchNotesSuccess() async {
        let notes = [MockAPIService.sampleNote(id: "1"), MockAPIService.sampleNote(id: "2")]
        mockService.fetchNotesResult = .success(notes)

        await sut.fetchNotes()

        XCTAssertTrue(mockService.fetchNotesCalled)
        XCTAssertEqual(sut.notes.count, 2)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }

    func testFetchNotesSetsIsLoading() async {
        mockService.fetchNotesResult = .success([])

        await sut.fetchNotes()

        XCTAssertFalse(sut.isLoading)
    }

    func testFetchNotesErrorSetsMessage() async {
        mockService.fetchNotesResult = .failure(APIError.unauthorized)

        await sut.fetchNotes()

        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.notes.isEmpty)
        XCTAssertFalse(sut.isLoading)
    }

    func testFetchNotesServerErrorMessage() async {
        mockService.fetchNotesResult = .failure(APIError.serverError(503))

        await sut.fetchNotes()

        XCTAssertTrue(sut.errorMessage?.contains("503") == true)
    }

    // MARK: - addNote

    func testAddNoteSuccess() async {
        let note = MockAPIService.sampleNote(id: "new", title: "New Note")
        mockService.createNoteResult = .success(note)

        await sut.addNote(title: "New Note", content: "Content")

        XCTAssertEqual(mockService.createNoteTitle, "New Note")
        XCTAssertEqual(mockService.createNoteContent, "Content")
        XCTAssertEqual(sut.notes.count, 1)
        XCTAssertEqual(sut.notes.first?.id, "new")
        XCTAssertNil(sut.errorMessage)
    }

    func testAddNoteInsertsAtBeginning() async {
        sut.notes = [MockAPIService.sampleNote(id: "existing")]
        let newNote = MockAPIService.sampleNote(id: "new")
        mockService.createNoteResult = .success(newNote)

        await sut.addNote(title: "T", content: "C")

        XCTAssertEqual(sut.notes.first?.id, "new")
    }

    func testAddNoteErrorSetsMessage() async {
        mockService.createNoteResult = .failure(APIError.serverError(500))

        await sut.addNote(title: "T", content: "C")

        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.notes.isEmpty)
    }

    // MARK: - deleteNote

    func testDeleteNoteSuccess() async {
        sut.notes = [
            MockAPIService.sampleNote(id: "1"),
            MockAPIService.sampleNote(id: "2"),
        ]
        mockService.deleteNoteResult = .success(())

        await sut.deleteNote(id: "1")

        XCTAssertEqual(mockService.deleteNoteId, "1")
        XCTAssertEqual(sut.notes.count, 1)
        XCTAssertEqual(sut.notes.first?.id, "2")
        XCTAssertNil(sut.errorMessage)
    }

    func testDeleteNoteErrorSetsMessage() async {
        sut.notes = [MockAPIService.sampleNote(id: "1")]
        mockService.deleteNoteResult = .failure(APIError.notFound)

        await sut.deleteNote(id: "1")

        XCTAssertNotNil(sut.errorMessage)
        XCTAssertEqual(sut.notes.count, 1)
    }

    // MARK: - toggleFavorite

    func testToggleFavorite() {
        sut.notes = [MockAPIService.sampleNote(id: "1")]
        XCTAssertFalse(sut.notes[0].isFavorited)

        sut.toggleFavorite(note: sut.notes[0])
        XCTAssertTrue(sut.notes[0].isFavorited)

        sut.toggleFavorite(note: sut.notes[0])
        XCTAssertFalse(sut.notes[0].isFavorited)
    }

    func testToggleFavoriteNonexistentNote() {
        sut.notes = [MockAPIService.sampleNote(id: "1")]
        let nonexistent = MockAPIService.sampleNote(id: "999")

        sut.toggleFavorite(note: nonexistent)

        XCTAssertFalse(sut.notes[0].isFavorited)
    }

    // MARK: - Error descriptions

    func testUnauthorizedErrorDescription() async {
        mockService.fetchNotesResult = .failure(APIError.unauthorized)
        await sut.fetchNotes()
        XCTAssertEqual(sut.errorMessage, "Authorization failed. Please log in again.")
    }

    func testNotFoundErrorDescription() async {
        mockService.fetchNotesResult = .failure(APIError.notFound)
        await sut.fetchNotes()
        XCTAssertEqual(sut.errorMessage, "The requested resource was not found.")
    }

    func testDecodingErrorDescription() async {
        let decodingError = DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "test"))
        mockService.fetchNotesResult = .failure(APIError.decodingError(decodingError))
        await sut.fetchNotes()
        XCTAssertEqual(sut.errorMessage, "Failed to process server response.")
    }

    func testTransportErrorDescription() async {
        mockService.fetchNotesResult = .failure(APIError.transportError(URLError(.notConnectedToInternet)))
        await sut.fetchNotes()
        XCTAssertEqual(sut.errorMessage, "Network error. Check your connection.")
    }
}
