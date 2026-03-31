import Foundation

@MainActor
final class NotesViewModel: ObservableObject {
    @Published var notes: [Note] = []
    @Published var errorMessage: String?
    @Published var isLoading = false

    private let apiService = APIService()

    /// Fetch notes from the backend API
    func fetchNotes() async {
        isLoading = true
        errorMessage = nil
        do {
            notes = try await apiService.fetchNotes()
        } catch let error as APIError {
            errorMessage = error.errorDescription
            notes = []
        } catch {
            errorMessage = error.localizedDescription
            notes = []
        }
        isLoading = false
    }
}
