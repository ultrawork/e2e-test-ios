import Foundation

@MainActor
final class NotesViewModel: ObservableObject {
    @Published var notes: [Note] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let apiService: APIServiceProtocol

    init(apiService: APIServiceProtocol = APIService()) {
        self.apiService = apiService
    }

    func fetchNotes() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            notes = try await apiService.fetchNotes()
        } catch {
            if error is CancellationError { return }
            errorMessage = errorDescription(error)
        }
    }

    func addNote(title: String, content: String) async {
        do {
            let note = try await apiService.createNote(title: title, content: content)
            notes.insert(note, at: 0)
        } catch {
            if error is CancellationError { return }
            errorMessage = errorDescription(error)
        }
    }

    func deleteNote(id: String) async {
        do {
            try await apiService.deleteNote(id: id)
            notes.removeAll { $0.id == id }
        } catch {
            if error is CancellationError { return }
            errorMessage = errorDescription(error)
        }
    }

    func toggleFavorite(note: Note) {
        guard let index = notes.firstIndex(where: { $0.id == note.id }) else { return }
        notes[index].isFavorited.toggle()
    }

    private func errorDescription(_ error: Error) -> String {
        switch error {
        case APIError.unauthorized:
            return "Authorization failed. Please log in again."
        case APIError.notFound:
            return "The requested resource was not found."
        case APIError.serverError(let code):
            return "Server error (\(code)). Please try again later."
        case APIError.decodingError:
            return "Failed to process server response."
        case APIError.transportError:
            return "Network error. Check your connection."
        default:
            return error.localizedDescription
        }
    }
}
