import XCTest
@testable import NotesApp

@MainActor
final class NotesViewModelTests: XCTestCase {

    private var mockService: MockAPIService!
    private var viewModel: NotesViewModel!

    override func setUp() {
        super.setUp()
        mockService = MockAPIService()
        viewModel = NotesViewModel(apiService: mockService)
        UserDefaults.standard.removeObject(forKey: "authToken")
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "authToken")
        super.tearDown()
    }

    // MARK: - load()

    func testLoad_fetchesDevTokenWhenMissing() async {
        mockService.fetchDevTokenResult = .success("test-token-123")
        mockService.fetchNotesResult = .success([])

        await viewModel.load()

        XCTAssertTrue(mockService.fetchDevTokenCalled)
        XCTAssertEqual(UserDefaults.standard.string(forKey: "authToken"), "test-token-123")
    }

    func testLoad_skipsDevTokenWhenPresent() async {
        UserDefaults.standard.set("existing-token", forKey: "authToken")
        mockService.fetchNotesResult = .success([])

        await viewModel.load()

        XCTAssertFalse(mockService.fetchDevTokenCalled)
    }

    func testLoad_fetchesNotes() async {
        let notes = [
            Note(id: "1", title: "Note 1", content: "Content", createdAt: Date(), updatedAt: Date(), categories: [])
        ]
        mockService.fetchNotesResult = .success(notes)

        await viewModel.load()

        XCTAssertTrue(mockService.fetchNotesCalled)
        XCTAssertEqual(viewModel.notes.count, 1)
        XCTAssertEqual(viewModel.notes.first?.title, "Note 1")
        XCTAssertFalse(viewModel.isLoading)
    }

    func testLoad_setsErrorOnFailure() async {
        mockService.fetchNotesResult = .failure(APIError.httpError(500))

        await viewModel.load()

        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }

    // MARK: - addNote()

    func testAddNote_insertsAtTop() async {
        let newNote = Note(id: "new-1", title: "New Note", content: "", createdAt: Date(), updatedAt: Date(), categories: [])
        mockService.createNoteResult = .success(newNote)

        await viewModel.addNote(title: "New Note")

        XCTAssertTrue(mockService.createNoteCalled)
        XCTAssertEqual(mockService.lastCreatedTitle, "New Note")
        XCTAssertEqual(viewModel.notes.first?.id, "new-1")
    }

    func testAddNote_setsErrorOnFailure() async {
        mockService.createNoteResult = .failure(APIError.httpError(400))

        await viewModel.addNote(title: "Fail")

        XCTAssertNotNil(viewModel.errorMessage)
    }

    // MARK: - deleteNote()

    func testDeleteNote_removesFromList() async {
        let note = Note(id: "del-1", title: "To Delete", content: "", createdAt: Date(), updatedAt: Date(), categories: [])
        viewModel.notes = [note]
        mockService.deleteNoteResult = .success(())

        await viewModel.deleteNote(note)

        XCTAssertTrue(mockService.deleteNoteCalled)
        XCTAssertEqual(mockService.lastDeletedId, "del-1")
        XCTAssertTrue(viewModel.notes.isEmpty)
    }

    func testDeleteNote_setsErrorOnFailure() async {
        let note = Note(id: "del-2", title: "Fail Delete", content: "", createdAt: Date(), updatedAt: Date(), categories: [])
        viewModel.notes = [note]
        mockService.deleteNoteResult = .failure(APIError.httpError(500))

        await viewModel.deleteNote(note)

        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.notes.count, 1, "Note should remain if delete fails")
    }

    // MARK: - toggleFavorite()

    func testToggleFavorite_togglesLocalFlag() {
        let note = Note(id: "fav-1", title: "Fav", content: "", createdAt: Date(), updatedAt: Date(), categories: [])
        viewModel.notes = [note]

        XCTAssertFalse(viewModel.notes[0].isFavorited)

        viewModel.toggleFavorite(note)
        XCTAssertTrue(viewModel.notes[0].isFavorited)

        viewModel.toggleFavorite(viewModel.notes[0])
        XCTAssertFalse(viewModel.notes[0].isFavorited)
    }
}
