import Foundation

@MainActor
final class NotesViewModel: ObservableObject {
    @Published var notes: [Note] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private let apiService: APIServiceProtocol

    init(apiService: APIServiceProtocol = APIService()) {
        self.apiService = apiService
    }

    func fetchNotes() async {
        isLoading = true
        errorMessage = nil

        do {
            notes = try await apiService.fetchNotes()
        } catch let error as APIError {
            switch error {
            case .unauthorized:
                errorMessage = "Unauthorized"
            case .networkError:
                errorMessage = "Network error"
            case .decodingError:
                errorMessage = "Decoding error"
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
