import Foundation

/// ViewModel for managing notes with API integration.
@MainActor
final class NotesViewModel: ObservableObject {
    @Published var notes: [Note] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiService: APIServiceProtocol

    init(apiService: APIServiceProtocol = APIService.shared) {
        self.apiService = apiService
    }

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

    func addNote(title: String, content: String) async {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isLoading = true
        errorMessage = nil
        do {
            let note = try await apiService.createNote(title: title, content: content)
            notes.insert(note, at: 0)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func deleteNote(id: String) async {
        errorMessage = nil
        do {
            try await apiService.deleteNote(id: id)
            notes.removeAll { $0.id == id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleFavorite(note: Note) {
        guard let index = notes.firstIndex(where: { $0.id == note.id }) else { return }
        notes[index].isFavorited.toggle()
    }
}
