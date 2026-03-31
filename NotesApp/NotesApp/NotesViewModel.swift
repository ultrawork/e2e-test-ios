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

    /// Create a new note and append to the list
    func createNote(content: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let newNote = try await apiService.createNote(content: content)
            notes.append(newNote)
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    /// Delete note by id and remove from the list
    func deleteNote(id: String) async {
        isLoading = true
        errorMessage = nil
        do {
            try await apiService.deleteNote(id: id)
            notes.removeAll { $0.id == id }
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
