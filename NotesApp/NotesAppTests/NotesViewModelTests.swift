import XCTest
@testable import NotesApp

/// Mock-реализация APIServiceProtocol для тестов ViewModel.
private final class MockAPIService: APIServiceProtocol {
    var result: Result<[Note], Error> = .success([])
    var isLoadingWhenCalled: Bool?
    weak var viewModel: NotesViewModel?

    func fetchNotes() async throws -> [Note] {
        if let viewModel = viewModel {
            await MainActor.run {
                isLoadingWhenCalled = viewModel.isLoading
            }
        }
        return try result.get()
    }
}

@MainActor
final class NotesViewModelTests: XCTestCase {

    /// Проверяет, что успешный запрос заполняет notes и сбрасывает isLoading.
    func test_fetchNotes_success_populatesNotes() async {
        let mockService = MockAPIService()
        mockService.result = .success([
            Note(id: 1, text: "Hello"),
            Note(id: 2, text: "World")
        ])

        let viewModel = NotesViewModel(apiService: mockService)
        await viewModel.fetchNotes()

        XCTAssertEqual(viewModel.notes.count, 2)
        XCTAssertEqual(viewModel.notes[0].text, "Hello")
        XCTAssertEqual(viewModel.notes[1].text, "World")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }

    /// Проверяет, что APIError.unauthorized устанавливает errorMessage = "Unauthorized".
    func test_fetchNotes_unauthorized_setsErrorMessage() async {
        let mockService = MockAPIService()
        mockService.result = .failure(APIError.unauthorized)

        let viewModel = NotesViewModel(apiService: mockService)
        await viewModel.fetchNotes()

        XCTAssertEqual(viewModel.errorMessage, "Unauthorized")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertTrue(viewModel.notes.isEmpty)
    }

    /// Проверяет, что isLoading = true во время выполнения запроса.
    func test_fetchNotes_setsIsLoadingDuringFetch() async {
        let mockService = MockAPIService()
        mockService.result = .success([Note(id: 1, text: "Test")])

        let viewModel = NotesViewModel(apiService: mockService)
        mockService.viewModel = viewModel

        await viewModel.fetchNotes()

        XCTAssertTrue(mockService.isLoadingWhenCalled == true)
        XCTAssertFalse(viewModel.isLoading)
    }
}
