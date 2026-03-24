import Foundation

/// Errors returned by APIService.
enum APIError: LocalizedError, Equatable {
    case unauthorized
    case invalidResponse
    case serverError(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Unauthorized"
        case .invalidResponse:
            return "Invalid response"
        case .serverError(let statusCode):
            return "Server error: \(statusCode)"
        }
    }
}

/// Protocol for API operations.
protocol APIServiceProtocol {
    func fetchNotes() async throws -> [NoteDTO]
}

/// DTO for notes from API.
struct NoteDTO: Codable {
    let id: String
    let text: String
}

/// Service for API communication with token-based authorization.
final class APIService: APIServiceProtocol {
    private let baseURL: URL
    private let session: URLSession

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    /// Fetches notes from the API with token-based authorization.
    func fetchNotes() async throws -> [NoteDTO] {
        let url = baseURL.appendingPathComponent("api/notes")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        if let token = UserDefaults.standard.string(forKey: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await session.data(for: request)
        try validate(response: response)
        return try JSONDecoder().decode([NoteDTO].self, from: data)
    }

    private func validate(response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        switch httpResponse.statusCode {
        case 200..<300:
            return
        case 401:
            throw APIError.unauthorized
        default:
            throw APIError.serverError(statusCode: httpResponse.statusCode)
        }
    }
}
