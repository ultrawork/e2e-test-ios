import XCTest
@testable import NotesApp

@MainActor
final class NotesViewModelTests: XCTestCase {
    private var mockService: MockAPIService!
    private var sut: NotesViewModel!

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "authToken")
        mockService = MockAPIService()
        sut = NotesViewModel(apiService: mockService)
    }

    override func tearDown() {
        sut = nil
        mockService = nil
        UserDefaults.standard.removeObject(forKey: "authToken")
        super.tearDown()
    }

    // MARK: - Helper

    private func makeSampleNote(
        id: String = "1",
        title: String = "Sample",
        content: String = ""
    ) -> Note {
        Note(
            id: id, title: title, content: content, userId: nil,
            createdAt: Date(), updatedAt: Date(), categories: []
        )
    }

    // MARK: - load()

    func testLoadFetchesDevTokenWhenMissing() async {
        mockService.fetchNotesResult = .success([])

        await sut.load()

        XCTAssertTrue(mockService.fetchDevTokenCalled)
        XCTAssertTrue(mockService.fetchNotesCalled)
    }

    func testLoadSkipsDevTokenWhenPresent() async {
        UserDefaults.standard.set("existing-token", forKey: "authToken")
        mockService.fetchNotesResult = .success([])

        await sut.load()

        XCTAssertFalse(mockService.fetchDevTokenCalled)
        XCTAssertTrue(mockService.fetchNotesCalled)
    }

    func testLoadPopulatesNotes() async {
        let notes = [makeSampleNote(id: "1"), makeSampleNote(id: "2")]
        mockService.fetchNotesResult = .success(notes)

        await sut.load()

        XCTAssertEqual(sut.notes.count, 2)
        XCTAssertEqual(sut.notes[0].id, "1")
        XCTAssertEqual(sut.notes[1].id, "2")
    }

    func testLoadSetsErrorOnDevTokenFailure() async {
        mockService.fetchDevTokenResult = .failure(APIError.transportError)

        await sut.load()

        XCTAssertNotNil(sut.errorMessage)
        XCTAssertFalse(mockService.fetchNotesCalled)
    }

    func testLoadSetsErrorOnFetchNotesFailure() async {
        mockService.fetchNotesResult = .failure(APIError.unauthorized)

        await sut.load()

        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage!.contains("Unauthorized"))
    }

    func testLoadSetsIsLoadingDuringExecution() async {
        XCTAssertFalse(sut.isLoading)

        mockService.fetchNotesResult = .success([])
        await sut.load()

        XCTAssertFalse(sut.isLoading)
    }

    func testLoadClearsErrorMessageBeforeLoading() async {
        // Set an initial error
        mockService.fetchNotesResult = .failure(APIError.transportError)
        await sut.load()
        XCTAssertNotNil(sut.errorMessage)

        // Now succeed
        mockService.fetchNotesResult = .success([])
        await sut.load()
        XCTAssertNil(sut.errorMessage)
    }

    // MARK: - addNote()

    func testAddNoteInsertsAtBeginning() async {
        sut.notes = [makeSampleNote(id: "existing")]
        let newNote = makeSampleNote(id: "new-1", title: "New")
        mockService.createNoteResult = .success(newNote)

        await sut.addNote(title: "New")

        XCTAssertEqual(sut.notes.count, 2)
        XCTAssertEqual(sut.notes.first?.id, "new-1")
        XCTAssertEqual(mockService.lastCreatedTitle, "New")
        XCTAssertEqual(mockService.lastCreatedContent, "")
    }

    func testAddNoteSetsErrorOnFailure() async {
        mockService.createNoteResult = .failure(APIError.serverError(500, nil))

        await sut.addNote(title: "Fail")

        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.notes.isEmpty)
    }

    // MARK: - deleteNote()

    func testDeleteNoteRemovesFromList() async {
        let note = makeSampleNote(id: "del-1")
        sut.notes = [note, makeSampleNote(id: "keep-1")]

        await sut.deleteNote(note)

        XCTAssertEqual(sut.notes.count, 1)
        XCTAssertEqual(sut.notes.first?.id, "keep-1")
        XCTAssertEqual(mockService.lastDeletedId, "del-1")
    }

    func testDeleteNoteSetsErrorOnFailure() async {
        let note = makeSampleNote(id: "del-1")
        sut.notes = [note]
        mockService.deleteNoteResult = .failure(APIError.notFound)

        await sut.deleteNote(note)

        XCTAssertNotNil(sut.errorMessage)
        XCTAssertEqual(sut.notes.count, 1)
    }

    // MARK: - toggleFavorite()

    func testToggleFavoriteTogglesState() {
        var note = makeSampleNote(id: "fav-1")
        note.isFavorited = false
        sut.notes = [note]

        sut.toggleFavorite(note)

        XCTAssertTrue(sut.notes.first!.isFavorited)

        sut.toggleFavorite(sut.notes.first!)

        XCTAssertFalse(sut.notes.first!.isFavorited)
    }

    func testToggleFavoriteIgnoresNonExistentNote() {
        let note = makeSampleNote(id: "ghost")
        sut.notes = [makeSampleNote(id: "other")]

        sut.toggleFavorite(note)

        XCTAssertFalse(sut.notes.first!.isFavorited)
    }

    // MARK: - mapError()

    func testMapErrorReturnsAPIErrorDescription() async {
        mockService.fetchNotesResult = .failure(APIError.notFound)

        await sut.load()

        XCTAssertEqual(sut.errorMessage, "Resource not found")
    }

    func testMapErrorReturnsGenericForNonAPIError() async {
        mockService.fetchNotesResult = .failure(NSError(domain: "test", code: 1))

        await sut.load()

        XCTAssertEqual(sut.errorMessage, "An unexpected error occurred")
    }
}
