import Foundation

final class NotesViewModel: ObservableObject {
    @Published var notes: [Note] = []
    @Published var showFavoritesOnly: Bool = false

    /// Переключает статус избранного для заметки по id.
    func toggleFavorite(id: UUID) {
        guard let index = notes.firstIndex(where: { $0.id == id }) else { return }
        notes[index].isFavorited.toggle()
    }

    /// Переключает режим отображения только избранных.
    func toggleShowFavoritesOnly() {
        showFavoritesOnly.toggle()
    }
}
