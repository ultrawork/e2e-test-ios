import Foundation

@MainActor
final class NotesViewModel: ObservableObject {
    @Published var notes: [Note] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func loadNotes() async {
        isLoading = true
        defer { isLoading = false }
        do {
            notes = try await APIService.shared.fetchNotes()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addNote(title: String) async {
        do {
            let note = try await APIService.shared.createNote(title: title, content: "")
            notes.insert(note, at: 0)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteNote(id: String) async {
        do {
            try await APIService.shared.deleteNote(id: id)
            notes.removeAll { $0.id == id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

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
