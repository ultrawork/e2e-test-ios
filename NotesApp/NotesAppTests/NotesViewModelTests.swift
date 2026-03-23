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
            MockAPIService.makeNote(id: "1", title: "Note 1"),
            MockAPIService.makeNote(id: "2", title: "Note 2"),
        ]
        mockService.fetchNotesResult = .success(notes)

        await viewModel.fetchNotes()

        XCTAssertTrue(mockService.fetchNotesCalled)
        XCTAssertEqual(viewModel.notes.count, 2)
        XCTAssertEqual(viewModel.notes[0].title, "Note 1")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testFetchNotesError() async {
        mockService.fetchNotesResult = .failure(APIError.unauthorized)

        await viewModel.fetchNotes()

        XCTAssertTrue(viewModel.notes.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    // MARK: - addNote

    func testAddNoteSuccess() async {
        let created = MockAPIService.makeNote(id: "new-1", title: "New note")
        mockService.createNoteResult = .success(created)

        await viewModel.addNote(title: "New note")

        XCTAssertEqual(mockService.createNoteCalledWith?.title, "New note")
        XCTAssertEqual(viewModel.notes.count, 1)
        XCTAssertEqual(viewModel.notes.first?.id, "new-1")
    }

    func testAddNoteEmptyTitleSkipped() async {
        await viewModel.addNote(title: "   ")

        XCTAssertNil(mockService.createNoteCalledWith)
        XCTAssertTrue(viewModel.notes.isEmpty)
    }

    func testAddNoteError() async {
        mockService.createNoteResult = .failure(APIError.serverError(500))

        await viewModel.addNote(title: "Fail note")

        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.notes.isEmpty)
    }

    // MARK: - deleteNote

    func testDeleteNoteSuccess() async {
        let note = MockAPIService.makeNote(id: "del-1", title: "To delete")
        viewModel.notes = [note]

        await viewModel.deleteNote(note)

        XCTAssertEqual(mockService.deleteNoteCalledWith, "del-1")
        XCTAssertTrue(viewModel.notes.isEmpty)
    }

    func testDeleteNoteError() async {
        let note = MockAPIService.makeNote(id: "del-2", title: "Keep")
        viewModel.notes = [note]
        mockService.deleteNoteResult = .failure(APIError.notFound)

        await viewModel.deleteNote(note)

        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.notes.count, 1)
    }

    // MARK: - toggleFavorite

    func testToggleFavorite() {
        var note = MockAPIService.makeNote(id: "fav-1", title: "Fav")
        note.isFavorited = false
        viewModel.notes = [note]

        viewModel.toggleFavorite(note)

        XCTAssertTrue(viewModel.notes[0].isFavorited)

        viewModel.toggleFavorite(viewModel.notes[0])
        XCTAssertFalse(viewModel.notes[0].isFavorited)
    }
}
