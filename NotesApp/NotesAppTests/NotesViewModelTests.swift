import XCTest
@testable import NotesApp

@MainActor
final class NotesViewModelTests: XCTestCase {

    private var mockAPI: MockAPIService!
    private var viewModel: NotesViewModel!

    override func setUp() {
        super.setUp()
        mockAPI = MockAPIService()
        viewModel = NotesViewModel(api: mockAPI)
    }

    override func tearDown() {
        viewModel = nil
        mockAPI = nil
        super.tearDown()
    }

    // MARK: - loadNotes

    func testLoadNotesSuccess() async {
        let expected = [
            Note(id: "1", title: "First", content: "Content 1"),
            Note(id: "2", title: "Second", content: "Content 2")
        ]
        mockAPI.fetchNotesResult = .success(expected)

        await viewModel.loadNotes()

        XCTAssertTrue(mockAPI.fetchNotesCalled)
        XCTAssertEqual(viewModel.notes.count, 2)
        XCTAssertEqual(viewModel.notes[0].id, "1")
        XCTAssertEqual(viewModel.notes[1].title, "Second")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
    }

    func testLoadNotesReturnsEmptyOnUnauthorized() async {
        mockAPI.fetchNotesResult = .success([])

        await viewModel.loadNotes()

        XCTAssertEqual(viewModel.notes, [])
        XCTAssertNil(viewModel.error)
    }

    func testLoadNotesHandlesError() async {
        let testError = NSError(domain: "test", code: 500, userInfo: [NSLocalizedDescriptionKey: "Server error"])
        mockAPI.fetchNotesResult = .failure(testError)

        await viewModel.loadNotes()

        XCTAssertEqual(viewModel.notes, [])
        XCTAssertNotNil(viewModel.error)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testLoadNotesSetsIsLoading() async {
        mockAPI.fetchNotesResult = .success([])

        await viewModel.loadNotes()

        // After completion, isLoading should be false
        XCTAssertFalse(viewModel.isLoading)
    }

    // MARK: - addNote

    func testAddNoteSuccess() async {
        let newNote = Note(id: "new-1", title: "New", content: "New content")
        mockAPI.createNoteResult = .success(newNote)

        await viewModel.addNote(title: "New", content: "New content")

        XCTAssertEqual(mockAPI.createNoteCallArgs.count, 1)
        XCTAssertEqual(mockAPI.createNoteCallArgs[0].title, "New")
        XCTAssertEqual(mockAPI.createNoteCallArgs[0].content, "New content")
        XCTAssertEqual(viewModel.notes.count, 1)
        XCTAssertEqual(viewModel.notes[0].id, "new-1")
        XCTAssertNil(viewModel.error)
    }

    func testAddNoteAppendsToExistingNotes() async {
        let existing = Note(id: "1", title: "Existing", content: "Content")
        mockAPI.fetchNotesResult = .success([existing])
        await viewModel.loadNotes()

        let newNote = Note(id: "2", title: "New", content: "New content")
        mockAPI.createNoteResult = .success(newNote)
        await viewModel.addNote(title: "New", content: "New content")

        XCTAssertEqual(viewModel.notes.count, 2)
        XCTAssertEqual(viewModel.notes[0].id, "1")
        XCTAssertEqual(viewModel.notes[1].id, "2")
    }

    func testAddNoteHandlesError() async {
        let testError = NSError(domain: "test", code: 400, userInfo: [NSLocalizedDescriptionKey: "Bad request"])
        mockAPI.createNoteResult = .failure(testError)

        await viewModel.addNote(title: "New", content: "New content")

        XCTAssertEqual(viewModel.notes.count, 0)
        XCTAssertNotNil(viewModel.error)
    }

    // MARK: - deleteNote

    func testDeleteNoteSuccess() async {
        let notes = [
            Note(id: "1", title: "First", content: "C1"),
            Note(id: "2", title: "Second", content: "C2")
        ]
        mockAPI.fetchNotesResult = .success(notes)
        await viewModel.loadNotes()

        mockAPI.deleteNoteResult = .success(())
        await viewModel.deleteNote(id: "1")

        XCTAssertEqual(mockAPI.deleteNoteCallArgs, ["1"])
        XCTAssertEqual(viewModel.notes.count, 1)
        XCTAssertEqual(viewModel.notes[0].id, "2")
        XCTAssertNil(viewModel.error)
    }

    func testDeleteNoteHandlesError() async {
        let notes = [Note(id: "1", title: "First", content: "C1")]
        mockAPI.fetchNotesResult = .success(notes)
        await viewModel.loadNotes()

        let testError = NSError(domain: "test", code: 404, userInfo: [NSLocalizedDescriptionKey: "Not found"])
        mockAPI.deleteNoteResult = .failure(testError)
        await viewModel.deleteNote(id: "1")

        // Note should NOT be removed on error
        XCTAssertEqual(viewModel.notes.count, 1)
        XCTAssertNotNil(viewModel.error)
    }
}
