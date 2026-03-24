import Foundation

/// Errors that can occur during API operations.
enum APIError: Error, LocalizedError, Equatable {
    case invalidBaseURL
    case invalidURL
    case unauthorized
    case notFound
    case serverError(Int, String?)
    case decodingError
    case encodingError
    case transportError
    case invalidResponse
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidBaseURL:
            return "Invalid base URL configuration"
        case .invalidURL:
            return "Invalid URL"
        case .unauthorized:
            return "Unauthorized. Please re-authenticate."
        case .notFound:
            return "Resource not found"
        case .serverError(let code, let message):
            return "Server error \(code): \(message ?? "Unknown")"
        case .decodingError:
            return "Failed to decode server response"
        case .encodingError:
            return "Failed to encode request data"
        case .transportError:
            return "Network connection error"
        case .invalidResponse:
            return "Invalid server response"
        case .unknown:
            return "Unknown error occurred"
        }
    }
}

/// Protocol for the notes API service.
protocol APIServiceProtocol {
    func fetchNotes() async throws -> [Note]
    func createNote(title: String, content: String) async throws -> Note
    func deleteNote(id: String) async throws
    func fetchDevToken() async throws
}

/// Concrete implementation of APIServiceProtocol that communicates with the backend.
final class APIService: APIServiceProtocol {
    private let baseURL: String
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(session: URLSession = .shared) {
        if let plistURL = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String,
           !plistURL.isEmpty {
            self.baseURL = plistURL
        } else {
            self.baseURL = "http://localhost:3000"
        }
        self.session = session

        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601

        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
    }

    /// Fetches all notes from the API.
    func fetchNotes() async throws -> [Note] {
        let request = try makeRequest(path: "/api/notes", method: "GET")
        return try await perform(request)
    }

    /// Creates a new note with the given title and content.
    func createNote(title: String, content: String) async throws -> Note {
        var request = try makeRequest(path: "/api/notes", method: "POST")
        let body = ["title": title, "content": content]
        guard let httpBody = try? encoder.encode(body) else {
            throw APIError.encodingError
        }
        request.httpBody = httpBody
        return try await perform(request)
    }

    /// Deletes a note by its ID.
    func deleteNote(id: String) async throws {
        let request = try makeRequest(path: "/api/notes/\(id)", method: "DELETE")
        let (_, response) = try await performRaw(request)
        try validateResponse(response)
    }

    /// Fetches a dev token and stores it in UserDefaults.
    func fetchDevToken() async throws {
        let request = try makeRequest(path: "/api/auth/dev-token", method: "POST", authenticated: false)
        let (data, response) = try await performRaw(request)
        try validateResponse(response)

        struct TokenResponse: Decodable {
            let token: String
        }

        guard let tokenResponse = try? decoder.decode(TokenResponse.self, from: data) else {
            throw APIError.decodingError
        }

        UserDefaults.standard.set(tokenResponse.token, forKey: "authToken")
    }

    // MARK: - Private helpers

    private func makeRequest(path: String, method: String, authenticated: Bool = true) throws -> URLRequest {
        guard let url = URL(string: baseURL + path) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if authenticated, let token = UserDefaults.standard.string(forKey: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return request
    }

    private func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await performRaw(request)
        try validateResponse(response)

        guard let decoded = try? decoder.decode(T.self, from: data) else {
            throw APIError.decodingError
        }
        return decoded
    }

    private func performRaw(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch {
            throw APIError.transportError
        }
    }

    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401:
            throw APIError.unauthorized
        case 404:
            throw APIError.notFound
        default:
            throw APIError.serverError(httpResponse.statusCode, nil)
        }
    }
}
