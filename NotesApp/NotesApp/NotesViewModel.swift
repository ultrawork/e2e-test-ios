import Foundation

@MainActor
final class NotesViewModel: ObservableObject {
    @Published var notes: [Note] = []
    @Published var errorMessage: String?
    @Published var isLoading = false

    private let apiService = APIService()

    /// Handle unauthorized error: clear token and notes
    private func handleUnauthorized() {
        UserDefaults.standard.removeObject(forKey: "token")
        notes = []
    }

    /// Fetch notes from the backend API
    func fetchNotes() async {
        isLoading = true
        errorMessage = nil
        do {
            notes = try await apiService.fetchNotes()
        } catch let error as APIError {
            if case .unauthorized = error {
                handleUnauthorized()
            } else {
                notes = []
            }
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
            notes = []
        }
        isLoading = false
    }

    /// Create a new note via API
    func createNote(text: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let created = try await apiService.createNote(content: text)
            notes.append(created)
        } catch let error as APIError {
            if case .unauthorized = error {
                handleUnauthorized()
            }
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    /// Delete a note via API
    func deleteNote(id: String) async {
        isLoading = true
        errorMessage = nil
        do {
            try await apiService.deleteNote(id: id)
            notes.removeAll { $0.id == id }
        } catch let error as APIError {
            if case .unauthorized = error {
                handleUnauthorized()
            }
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
