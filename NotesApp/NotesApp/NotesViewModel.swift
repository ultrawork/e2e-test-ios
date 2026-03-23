import Foundation

/// ViewModel that manages notes state and communicates with the API.
@MainActor
final class NotesViewModel: ObservableObject {
    @Published var notes: [Note] = []
    @Published var isLoading = false
    @Published var error: String?

    private let api = APIService.shared

    /// Loads all notes from the API.
    func loadNotes() async {
        isLoading = true
        error = nil
        do {
            notes = try await api.fetchNotes()
        } catch {
            self.error = error.localizedDescription
            notes = []
        }
        isLoading = false
    }

    /// Creates a new note and appends it to the list.
    func addNote(title: String, content: String) async {
        do {
            let note = try await api.createNote(title: title, content: content)
            notes.append(note)
        } catch {
            self.error = error.localizedDescription
        }
    }

    /// Deletes a note by ID and removes it from the list.
    func deleteNote(id: String) async {
        do {
            try await api.deleteNote(id: id)
            notes.removeAll { $0.id == id }
        } catch {
            self.error = error.localizedDescription
        }
    }
}
