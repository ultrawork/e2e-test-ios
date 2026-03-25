import Foundation

@MainActor
final class NotesViewModel: ObservableObject {
    @Published var notes: [Note] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiService: APIServiceProtocol

    init(apiService: APIServiceProtocol = APIService()) {
        self.apiService = apiService
    }

    /// Loads notes from the API. Fetches a dev token first if none is stored.
    func load() async {
        isLoading = true
        errorMessage = nil

        do {
            if UserDefaults.standard.string(forKey: "authToken") == nil {
                let token = try await apiService.fetchDevToken()
                UserDefaults.standard.set(token, forKey: "authToken")
            }

            notes = try await apiService.fetchNotes()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    /// Creates a new note with the given title and inserts it at the top of the list.
    func addNote(title: String) async {
        do {
            let note = try await apiService.createNote(title: title, content: "")
            notes.insert(note, at: 0)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Deletes the given note via the API and removes it from the local list.
    func deleteNote(_ note: Note) async {
        do {
            try await apiService.deleteNote(id: note.id)
            notes.removeAll { $0.id == note.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Toggles the local-only `isFavorited` flag for the given note.
    func toggleFavorite(_ note: Note) {
        guard let index = notes.firstIndex(where: { $0.id == note.id }) else { return }
        notes[index].isFavorited.toggle()
    }
}
