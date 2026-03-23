import Foundation

/// ViewModel для управления заметками через API.
@MainActor
final class NotesViewModel: ObservableObject {
    @Published var notes: [Note] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let apiService: APIServiceProtocol

    init(apiService: APIServiceProtocol = APIService.shared) {
        self.apiService = apiService
    }

    /// Загружает заметки с сервера.
    func fetchNotes() async {
        isLoading = true
        errorMessage = nil
        do {
            notes = try await apiService.fetchNotes()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    /// Создаёт новую заметку и добавляет в начало списка.
    func addNote(title: String) async {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        do {
            let note = try await apiService.createNote(title: trimmed, content: trimmed)
            notes.insert(note, at: 0)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Удаляет заметку на сервере и из локального списка.
    func deleteNote(_ note: Note) async {
        do {
            try await apiService.deleteNote(id: note.id)
            notes.removeAll { $0.id == note.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Переключает статус избранного (только локально).
    func toggleFavorite(_ note: Note) {
        guard let index = notes.firstIndex(where: { $0.id == note.id }) else { return }
        notes[index] = apiService.toggleFavorite(note: notes[index])
    }
}
