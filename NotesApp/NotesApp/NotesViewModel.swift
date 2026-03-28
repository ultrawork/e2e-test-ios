import Foundation

/// ViewModel для управления списком заметок через API.
@MainActor
final class NotesViewModel: ObservableObject {
    @Published var notes: [Note] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let apiService: APIServiceProtocol

    init(apiService: APIServiceProtocol = APIService()) {
        self.apiService = apiService
    }

    /// Загружает список заметок с сервера.
    func fetchNotes() async {
        isLoading = true
        errorMessage = nil
        do {
            notes = try await apiService.fetchNotes()
        } catch let error as APIError {
            errorMessage = Self.message(for: error)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    /// Создаёт новую заметку на сервере и добавляет в локальный список.
    func createNote(text: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let note = try await apiService.createNote(text: text)
            notes.append(note)
        } catch let error as APIError {
            errorMessage = Self.message(for: error)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    /// Удаляет заметку на сервере и убирает из локального списка.
    func deleteNote(id: String) async {
        isLoading = true
        errorMessage = nil
        do {
            try await apiService.deleteNote(id: id)
            notes.removeAll { $0.id == id }
        } catch let error as APIError {
            errorMessage = Self.message(for: error)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private static func message(for error: APIError) -> String {
        switch error {
        case .unauthorized:
            return "Ошибка авторизации. Проверьте DEV_TOKEN."
        case .networkError(let underlying):
            return "Ошибка сети: \(underlying.localizedDescription)"
        case .decodingError:
            return "Ошибка обработки данных."
        case .notFound:
            return "Ресурс не найден."
        }
    }
}
