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

    // MARK: - fetchNotes

    func testFetchNotesSuccess() async {
        let notes = [
            Note(id: "1", title: "Test", content: "Content", userId: nil,
                 createdAt: Date(), updatedAt: Date(), categories: [])
        ]
        mockService.fetchNotesResult = .success(notes)

        await viewModel.fetchNotes()

        XCTAssertTrue(mockService.fetchNotesCalled)
        XCTAssertEqual(viewModel.notes.count, 1)
        XCTAssertEqual(viewModel.notes.first?.title, "Test")
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testFetchNotesFailureSetsErrorMessage() async {
        mockService.fetchNotesResult = .failure(APIError.serverError(500))

        await viewModel.fetchNotes()

        XCTAssertTrue(viewModel.notes.isEmpty)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }

    // MARK: - addNote

    func testAddNoteSuccess() async {
        await viewModel.addNote(title: "New Note", content: "Body")

        XCTAssertEqual(mockService.createNoteCalledWith?.title, "New Note")
        XCTAssertEqual(mockService.createNoteCalledWith?.content, "Body")
        XCTAssertEqual(viewModel.notes.count, 1)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testAddNoteEmptyTitleIsIgnored() async {
        await viewModel.addNote(title: "   ", content: "Body")

        XCTAssertNil(mockService.createNoteCalledWith)
        XCTAssertTrue(viewModel.notes.isEmpty)
    }

    func testAddNoteFailureSetsErrorMessage() async {
        mockService.createNoteResult = .failure(APIError.networkError(
            NSError(domain: "test", code: -1)
        ))

        await viewModel.addNote(title: "Note", content: "Body")

        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.notes.isEmpty)
    }

    // MARK: - deleteNote

    func testDeleteNoteSuccess() async {
        let note = Note(id: "42", title: "To delete", content: "c", userId: nil,
                        createdAt: Date(), updatedAt: Date(), categories: [])
        mockService.fetchNotesResult = .success([note])
        await viewModel.fetchNotes()

        await viewModel.deleteNote(id: "42")

        XCTAssertEqual(mockService.deleteNoteCalledWith, "42")
        XCTAssertTrue(viewModel.notes.isEmpty)
    }

    func testDeleteNoteFailureKeepsNote() async {
        let note = Note(id: "42", title: "Keep", content: "c", userId: nil,
                        createdAt: Date(), updatedAt: Date(), categories: [])
        mockService.fetchNotesResult = .success([note])
        await viewModel.fetchNotes()

        mockService.deleteNoteResult = .failure(APIError.serverError(500))
        await viewModel.deleteNote(id: "42")

        XCTAssertEqual(viewModel.notes.count, 1)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    // MARK: - toggleFavorite

    func testToggleFavorite() async {
        let note = Note(id: "1", title: "Fav", content: "c", userId: nil,
                        createdAt: Date(), updatedAt: Date(), categories: [])
        mockService.fetchNotesResult = .success([note])
        await viewModel.fetchNotes()

        XCTAssertFalse(viewModel.notes[0].isFavorited)

        viewModel.toggleFavorite(note: viewModel.notes[0])
        XCTAssertTrue(viewModel.notes[0].isFavorited)

        viewModel.toggleFavorite(note: viewModel.notes[0])
        XCTAssertFalse(viewModel.notes[0].isFavorited)
    }
}
