import Foundation

@MainActor
final class NotesViewModel: ObservableObject {
    @Published var notes: [Note] = []
    @Published var isLoading = false
    @Published var error: Error?

    private let apiService = APIService()

    /// Загружает список заметок с сервера.
    func loadNotes() async {
        isLoading = true
        error = nil
        do {
            notes = try await apiService.fetchNotes()
        } catch {
            self.error = error
        }
        isLoading = false
    }

    /// Создаёт новую заметку.
    func addNote(title: String) async {
        isLoading = true
        error = nil
        do {
            let note = try await apiService.createNote(title: title, content: "")
            notes.append(note)
        } catch {
            self.error = error
        }
        isLoading = false
    }

    /// Удаляет заметку по ID.
    func deleteNote(id: String) async {
        isLoading = true
        error = nil
        do {
            try await apiService.deleteNote(id: id)
            notes.removeAll { $0.id == id }
        } catch {
            self.error = error
        }
        isLoading = false
    }
}
