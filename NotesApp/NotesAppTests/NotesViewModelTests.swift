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
    }

    override func tearDown() {
        viewModel = nil
        mockService = nil
        super.tearDown()
    }

    // MARK: - fetchNotes

    func testFetchNotes_success_populatesNotes() async {
        let expected = [
            Note(id: "1", title: "Test", content: "Body", userId: nil,
                 createdAt: Date(), updatedAt: Date(), categories: [])
        ]
        mockService.fetchNotesResult = .success(expected)

        await viewModel.fetchNotes()

        XCTAssertTrue(mockService.fetchNotesCalled)
        XCTAssertEqual(viewModel.notes.count, 1)
        XCTAssertEqual(viewModel.notes.first?.title, "Test")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testFetchNotes_failure_setsErrorMessage() async {
        mockService.fetchNotesResult = .failure(APIError.unauthorized)

        await viewModel.fetchNotes()

        XCTAssertTrue(viewModel.notes.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    // MARK: - addNote

    func testAddNote_success_appendsNote() async {
        await viewModel.addNote(title: "New Note")

        XCTAssertEqual(mockService.createNoteCalledWith?.title, "New Note")
        XCTAssertEqual(mockService.createNoteCalledWith?.content, "New Note")
        XCTAssertEqual(viewModel.notes.count, 1)
    }

    func testAddNote_emptyTitle_doesNothing() async {
        await viewModel.addNote(title: "   ")

        XCTAssertNil(mockService.createNoteCalledWith)
        XCTAssertTrue(viewModel.notes.isEmpty)
    }

    func testAddNote_failure_setsErrorMessage() async {
        mockService.createNoteResult = .failure(APIError.serverError(500, nil))

        await viewModel.addNote(title: "Fail")

        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.notes.isEmpty)
    }

    // MARK: - deleteNote

    func testDeleteNote_success_removesNote() async {
        let note = Note(id: "1", title: "Del", content: "Body", userId: nil,
                        createdAt: Date(), updatedAt: Date(), categories: [])
        mockService.fetchNotesResult = .success([note])
        await viewModel.fetchNotes()

        await viewModel.deleteNote(note)

        XCTAssertEqual(mockService.deleteNoteCalledWithId, "1")
        XCTAssertTrue(viewModel.notes.isEmpty)
    }

    func testDeleteNote_failure_setsErrorMessageAndKeepsNote() async {
        let note = Note(id: "1", title: "Keep", content: "Body", userId: nil,
                        createdAt: Date(), updatedAt: Date(), categories: [])
        mockService.fetchNotesResult = .success([note])
        await viewModel.fetchNotes()

        mockService.deleteNoteError = APIError.serverError(500, nil)

        await viewModel.deleteNote(note)

        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.notes.count, 1)
    }

    // MARK: - toggleFavorite

    func testToggleFavorite_togglesLocalFlag() async {
        let note = Note(id: "1", title: "Fav", content: "Body", userId: nil,
                        createdAt: Date(), updatedAt: Date(), categories: [])
        mockService.fetchNotesResult = .success([note])
        await viewModel.fetchNotes()

        XCTAssertFalse(viewModel.notes[0].isFavorited)

        viewModel.toggleFavorite(viewModel.notes[0])
        XCTAssertTrue(viewModel.notes[0].isFavorited)

        viewModel.toggleFavorite(viewModel.notes[0])
        XCTAssertFalse(viewModel.notes[0].isFavorited)
    }
}
