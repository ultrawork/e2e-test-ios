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

    /// Loads all notes from the backend.
    func loadNotes() async {
        isLoading = true
        errorMessage = nil
        do {
            notes = try await apiService.fetchNotes()
        } catch let error as APIError {
            switch error {
            case .unauthorized:
                errorMessage = "Ошибка авторизации. Пожалуйста, войдите снова."
            default:
                errorMessage = "Не удалось загрузить заметки."
            }
        } catch {
            errorMessage = "Не удалось загрузить заметки."
        }
        isLoading = false
    }

    /// Creates a new note on the backend and appends it to the list.
    func addNote(text: String) async {
        do {
            let note = try await apiService.createNote(title: text, content: text)
            notes.append(note)
        } catch let error as APIError {
            switch error {
            case .unauthorized:
                errorMessage = "Ошибка авторизации. Пожалуйста, войдите снова."
            default:
                errorMessage = "Не удалось создать заметку."
            }
        } catch {
            errorMessage = "Не удалось создать заметку."
        }
    }

    /// Deletes a note on the backend and removes it from the list.
    func deleteNote(id: String) async {
        do {
            try await apiService.deleteNote(id: id)
            notes.removeAll { $0.id == id }
        } catch let error as APIError {
            switch error {
            case .unauthorized:
                errorMessage = "Ошибка авторизации. Пожалуйста, войдите снова."
            default:
                errorMessage = "Не удалось удалить заметку."
            }
        } catch {
            errorMessage = "Не удалось удалить заметку."
        }
    }

    /// Dismisses the current error message.
    func dismissError() {
        errorMessage = nil
    }
}
