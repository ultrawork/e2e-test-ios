import XCTest
@testable import NotesApp

// MARK: - MockAPIService

final class MockAPIService: APIServiceProtocol {
    var result: Result<[Note], Error> = .success([])
    var onFetch: (() -> Void)?

    func fetchNotes() async throws -> [Note] {
        onFetch?()
        return try result.get()
    }
}

// MARK: - NotesViewModelTests

@MainActor
final class NotesViewModelTests: XCTestCase {

    /// Verifies that successful fetch populates notes.
    func test_fetchNotes_success_populatesNotes() async {
        let mock = MockAPIService()
        let expected = [Note(id: "1", text: "Test note")]
        mock.result = .success(expected)

        let viewModel = NotesViewModel(apiService: mock)
        await viewModel.fetchNotes()

        XCTAssertEqual(viewModel.notes, expected)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }

    /// Verifies that a 401 error sets errorMessage to "Unauthorized" and clears notes.
    func test_fetchNotes_unauthorized_setsErrorMessage() async {
        let mock = MockAPIService()
        mock.result = .failure(APIError.unauthorized)

        let viewModel = NotesViewModel(apiService: mock)
        await viewModel.fetchNotes()

        XCTAssertEqual(viewModel.errorMessage, "Unauthorized")
        XCTAssertTrue(viewModel.notes.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
    }

    /// Verifies that isLoading is true during fetch and false after.
    func test_fetchNotes_setsIsLoadingDuringFetch() async {
        let mock = MockAPIService()
        mock.result = .success([Note(id: "1", text: "A")])

        var wasLoadingDuringFetch = false
        let viewModel = NotesViewModel(apiService: mock)

        mock.onFetch = {
            wasLoadingDuringFetch = viewModel.isLoading
        }

        await viewModel.fetchNotes()

        XCTAssertTrue(wasLoadingDuringFetch, "isLoading should be true during fetch")
        XCTAssertFalse(viewModel.isLoading, "isLoading should be false after fetch")
    }
}
