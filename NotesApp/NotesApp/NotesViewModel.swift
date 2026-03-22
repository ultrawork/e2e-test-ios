import Foundation

/// ViewModel для управления заметками
@MainActor
final class NotesViewModel: ObservableObject {
    @Published var notes: [Note] = []
    @Published var isLoading = false
    @Published var showFavoritesOnly = false
    @Published var errorMessage: String?

    private let apiService: APIServiceProtocol
    private let favoritesKey = "note_favorites"

    init(apiService: APIServiceProtocol = APIService.shared) {
        self.apiService = apiService
    }

    /// Загрузить заметки из API
    func loadNotes() async {
        isLoading = true
        errorMessage = nil
        do {
            var loaded = try await apiService.fetchNotes()
            restoreFavorites(notes: &loaded)
            notes = loaded
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    /// Добавить новую заметку
    func addNote(title: String) async {
        do {
            let note = try await apiService.createNote(title: title, content: "")
            notes.append(note)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Удалить заметку по ID
    func deleteNote(id: String) async {
        do {
            try await apiService.deleteNote(id: id)
            notes.removeAll { $0.id == id }
            persistFavorites()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Переключить избранное для заметки
    func toggleFavorite(note: Note) {
        guard let index = notes.firstIndex(where: { $0.id == note.id }) else { return }
        notes[index].isFavorited.toggle()
        persistFavorites()
    }

    /// Восстановить статус избранного из UserDefaults
    private func restoreFavorites(notes: inout [Note]) {
        let favoriteIds = Set(UserDefaults.standard.stringArray(forKey: favoritesKey) ?? [])
        for i in notes.indices where favoriteIds.contains(notes[i].id) {
            notes[i].isFavorited = true
        }
    }

    /// Сохранить ID избранных заметок в UserDefaults
    private func persistFavorites() {
        let favoriteIds = notes.filter(\.isFavorited).map(\.id)
        UserDefaults.standard.set(favoriteIds, forKey: favoritesKey)
    }
}
