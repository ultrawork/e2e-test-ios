import Foundation

/// ViewModel для управления заметками.
@MainActor
final class NotesViewModel: ObservableObject {
    @Published var notes: [Note] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let apiService: APIServiceProtocol

    init(apiService: APIServiceProtocol) {
        self.apiService = apiService
    }

    /// Загрузка заметок с сервера.
    func fetchNotes() async {
        isLoading = true
        errorMessage = nil
        do {
            notes = try await apiService.fetchNotes()
        } catch {
            errorMessage = mapError(error)
        }
        isLoading = false
    }

    /// Создание новой заметки.
    func addNote(title: String) async {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        do {
            let note = try await apiService.createNote(title: trimmed, content: trimmed)
            notes.append(note)
        } catch {
            errorMessage = mapError(error)
        }
    }

    /// Удаление заметки.
    func deleteNote(_ note: Note) async {
        do {
            try await apiService.deleteNote(id: note.id)
            notes.removeAll { $0.id == note.id }
        } catch {
            errorMessage = mapError(error)
        }
    }

    /// Локальное переключение избранного.
    func toggleFavorite(_ note: Note) {
        guard let index = notes.firstIndex(where: { $0.id == note.id }) else { return }
        notes[index].isFavorited.toggle()
    }

    // MARK: - Private

    private func mapError(_ error: Error) -> String {
        if let apiError = error as? APIError {
            return apiError.localizedDescription
        }
        return error.localizedDescription
    }
}
