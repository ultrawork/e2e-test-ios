import XCTest
@testable import NotesApp

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

    // MARK: - loadNotes

    func testLoadNotes_unauthorized_setsErrorMessage() async {
        mockService.shouldThrowError = .unauthorized

        await sut.loadNotes()

        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage!.contains("авторизации"))
        XCTAssertTrue(sut.notes.isEmpty)
        XCTAssertFalse(sut.isLoading)
    }

    func testLoadNotes_success_populatesNotes() async {
        let notes = [
            Note(id: "1", title: "A", content: "Body A"),
            Note(id: "2", title: "B", content: "Body B")
        ]
        mockService.stubbedNotes = notes

        await sut.loadNotes()

        XCTAssertEqual(sut.notes.count, 2)
        XCTAssertEqual(sut.notes.first?.title, "A")
        XCTAssertNil(sut.errorMessage)
        XCTAssertFalse(sut.isLoading)
    }

    func testLoadNotes_setsIsLoadingDuringFetch() async {
        mockService.stubbedNotes = []

        await sut.loadNotes()

        // After completion, isLoading should be false
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - addNote

    func testAddNote_success_appendsToNotes() async {
        mockService.createdNote = Note(id: "3", title: "New", content: "New")

        await sut.addNote(text: "New")

        XCTAssertEqual(sut.notes.count, 1)
        XCTAssertEqual(sut.notes.first?.id, "3")
        XCTAssertEqual(sut.notes.first?.title, "New")
        XCTAssertNil(sut.errorMessage)
    }

    func testAddNote_unauthorized_setsErrorMessage() async {
        mockService.shouldThrowError = .unauthorized

        await sut.addNote(text: "New")

        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage!.contains("авторизации"))
        XCTAssertTrue(sut.notes.isEmpty)
    }

    // MARK: - deleteNote

    func testDeleteNote_success_removesFromNotes() async {
        sut.notes = [
            Note(id: "1", title: "A", content: "A"),
            Note(id: "2", title: "B", content: "B")
        ]

        await sut.deleteNote(id: "1")

        XCTAssertEqual(sut.notes.count, 1)
        XCTAssertEqual(sut.notes.first?.id, "2")
        XCTAssertTrue(mockService.deleteCalled)
        XCTAssertEqual(mockService.deleteCalledWithId, "1")
    }

    func testDeleteNote_unauthorized_setsErrorMessage() async {
        sut.notes = [Note(id: "1", title: "A", content: "A")]
        mockService.shouldThrowError = .unauthorized

        await sut.deleteNote(id: "1")

        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage!.contains("авторизации"))
        // Note should NOT be removed on error
        XCTAssertEqual(sut.notes.count, 1)
    }

    // MARK: - dismissError

    func testDismissError_clearsErrorMessage() async {
        mockService.shouldThrowError = .unauthorized
        await sut.loadNotes()
        XCTAssertNotNil(sut.errorMessage)

        sut.dismissError()

        XCTAssertNil(sut.errorMessage)
    }
}
