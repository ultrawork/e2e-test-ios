import Foundation

/// ViewModel for the notes list screen.
@MainActor
final class NotesViewModel: ObservableObject {
    @Published var notes: [Note] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiService: APIServiceProtocol

    init(apiService: APIServiceProtocol = APIService.shared) {
        self.apiService = apiService
    }

    /// Fetches notes from the API and updates published state.
    func fetchNotes() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            notes = try await apiService.fetchNotes()
        } catch APIError.unauthorized {
            errorMessage = "Unauthorized"
            notes = []
        } catch {
            errorMessage = error.localizedDescription
            notes = []
        }
    }
}
