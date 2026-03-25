import Foundation

@MainActor
final class NotesViewModel: ObservableObject {
    @Published var notes: [Note] = []
    @Published var isLoading = false
    @Published var error: Error?

    private let apiService: APIService

    init(apiService: APIService = APIService()) {
        self.apiService = apiService
    }

    /// Загружает список заметок с сервера.
    func loadNotes() async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            notes = try await apiService.fetchNotes()
        } catch {
            self.error = error
        }
    }

    /// Создаёт новую заметку.
    func addNote(title: String) async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            let note = try await apiService.createNote(title: title, content: title)
            notes.append(note)
        } catch {
            self.error = error
        }
    }

    /// Удаляет заметку по ID.
    func deleteNote(id: String) async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            try await apiService.deleteNote(id: id)
            notes.removeAll { $0.id == id }
        } catch {
            self.error = error
        }
    }
}
