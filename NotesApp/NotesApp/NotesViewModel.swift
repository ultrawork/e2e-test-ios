import Foundation

/// ViewModel that manages the list of notes and communicates with ``APIService``.
///
/// All methods are isolated to `@MainActor` so that `@Published` property
/// updates are always dispatched on the main thread.
@MainActor
final class NotesViewModel: ObservableObject {
    /// The current list of notes displayed in the UI.
    @Published var notes: [Note] = []
    /// Indicates whether a network request is in progress.
    @Published var isLoading = false
    /// A user-facing error message; set when an API call fails.
    @Published var errorMessage: String?

    /// Fetches all notes from the backend and replaces the local list.
    func loadNotes() async {
        isLoading = true
        defer { isLoading = false }
        do {
            notes = try await APIService.shared.fetchNotes()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Creates a new note with the given title and inserts it at the top of the list.
    /// - Parameter title: The title for the new note.
    func addNote(title: String) async {
        do {
            let note = try await APIService.shared.createNote(title: title, content: "")
            notes.insert(note, at: 0)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Deletes a note by its identifier and removes it from the local list.
    /// - Parameter id: The unique identifier of the note to delete.
    func deleteNote(id: String) async {
        do {
            try await APIService.shared.deleteNote(id: id)
            notes.removeAll { $0.id == id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Toggles the favorite status of a note and updates the local list.
    /// - Parameter id: The unique identifier of the note to toggle.
    func toggleFavorite(id: String) async {
        do {
            let updated = try await APIService.shared.toggleFavorite(id: id)
            if let index = notes.firstIndex(where: { $0.id == id }) {
                notes[index] = updated
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
