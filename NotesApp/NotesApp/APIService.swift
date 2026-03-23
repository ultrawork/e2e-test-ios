import Foundation

/// Ошибки API-сервиса.
enum APIError: Error, LocalizedError {
    case invalidURL
    case unauthorized
    case notFound
    case serverError(Int)
    case decodingError(Error)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .unauthorized:
            return "Unauthorized — please log in"
        case .notFound:
            return "Resource not found"
        case .serverError(let code):
            return "Server error: \(code)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

/// Протокол API-сервиса для DI и тестируемости.
protocol APIServiceProtocol {
    func fetchNotes() async throws -> [Note]
    func createNote(title: String, content: String) async throws -> Note
    func deleteNote(id: String) async throws
    func toggleFavorite(note: Note) -> Note
}

/// Реализация API-сервиса через URLSession async/await.
final class APIService: APIServiceProtocol {
    static let shared = APIService()

    var authToken: String = ""

    private let baseURL: String
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(baseURL: String? = nil, session: URLSession = .shared) {
        self.baseURL = baseURL
            ?? Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String
            ?? "http://localhost:3000"
        self.session = session

        self.decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        self.encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
    }

    func fetchNotes() async throws -> [Note] {
        let request = try makeRequest(path: "/api/notes", method: "GET")
        let (data, response) = try await performRequest(request)
        try validateResponse(response)
        do {
            return try decoder.decode([Note].self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    func createNote(title: String, content: String) async throws -> Note {
        let body: [String: String] = ["title": title, "content": content]
        let request = try makeRequest(path: "/api/notes", method: "POST", body: body)
        let (data, response) = try await performRequest(request)
        try validateResponse(response)
        do {
            return try decoder.decode(Note.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    func deleteNote(id: String) async throws {
        let request = try makeRequest(path: "/api/notes/\(id)", method: "DELETE")
        let (_, response) = try await performRequest(request)
        try validateResponse(response)
    }

    func toggleFavorite(note: Note) -> Note {
        var updated = note
        updated.isFavorited.toggle()
        return updated
    }

    // MARK: - Private

    private func makeRequest(path: String, method: String, body: (any Encodable)? = nil) throws -> URLRequest {
        guard let url = URL(string: baseURL + path) else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !authToken.isEmpty {
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        }
        if let body = body {
            request.httpBody = try encoder.encode(AnyEncodable(body))
        }
        return request
    }

    private func performRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }
    }

    private func validateResponse(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { return }
        switch http.statusCode {
        case 200...299:
            return
        case 401:
            throw APIError.unauthorized
        case 404:
            throw APIError.notFound
        default:
            throw APIError.serverError(http.statusCode)
        }
    }
}

/// Обёртка для type-erased Encodable.
private struct AnyEncodable: Encodable {
    private let encodeClosure: (Encoder) throws -> Void

    init(_ wrapped: any Encodable) {
        encodeClosure = { encoder in
            try wrapped.encode(to: encoder)
        }
    }

    func encode(to encoder: Encoder) throws {
        try encodeClosure(encoder)
    }
}
