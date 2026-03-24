import Foundation

/// ViewModel that manages notes state and communicates with the API.
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
                try await apiService.fetchDevToken()
            }
            try await fetchNotes()
        } catch {
            errorMessage = mapError(error)
        }

        isLoading = false
    }

    /// Fetches notes from the API and updates the published list.
    func fetchNotes() async throws {
        let fetched = try await apiService.fetchNotes()
        notes = fetched
    }

    /// Creates a new note with the given title.
    func addNote(title: String) async {
        do {
            let note = try await apiService.createNote(title: title, content: "")
            notes.insert(note, at: 0)
        } catch {
            errorMessage = mapError(error)
        }
    }

    /// Deletes the given note from the API and local list.
    func deleteNote(_ note: Note) async {
        do {
            try await apiService.deleteNote(id: note.id)
            notes.removeAll { $0.id == note.id }
        } catch {
            errorMessage = mapError(error)
        }
    }

    /// Toggles the local favorite state of a note.
    func toggleFavorite(_ note: Note) {
        guard let index = notes.firstIndex(where: { $0.id == note.id }) else { return }
        notes[index].isFavorited.toggle()
    }

    // MARK: - Private

    private func mapError(_ error: Error) -> String {
        if let apiError = error as? APIError {
            return apiError.localizedDescription
        }
        return "An unexpected error occurred"
    }
}
