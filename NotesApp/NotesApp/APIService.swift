import Foundation

/// Errors returned by the API layer.
enum APIError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case httpError(Int)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid server response"
        case .httpError(let code):
            return "Server error: \(code)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        }
    }
}

/// Protocol describing notes API operations.
protocol APIServiceProtocol {
    func fetchNotes() async throws -> [Note]
    func createNote(title: String, content: String) async throws -> Note
    func deleteNote(id: String) async throws
    func fetchDevToken() async throws -> String
}

/// Concrete API service that communicates with the backend.
final class APIService: APIServiceProtocol {
    private let baseURL: String
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(session: URLSession = .shared) {
        self.session = session

        if let envURL = ProcessInfo.processInfo.environment["API_BASE_URL"], !envURL.isEmpty {
            self.baseURL = envURL
        } else if let url = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String {
            self.baseURL = url
        } else {
            self.baseURL = "http://localhost:3001"
        }

        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: string) { return date }
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: string) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid ISO8601 date")
        }

        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
    }

    private var authToken: String? {
        UserDefaults.standard.string(forKey: "authToken")
    }

    private func makeRequest(path: String, method: String, body: Data? = nil) throws -> URLRequest {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        request.httpBody = body
        return request
    }

    private func perform(_ request: URLRequest) async throws -> Data {
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(httpResponse.statusCode)
        }

        return data
    }

    // MARK: - APIServiceProtocol

    func fetchDevToken() async throws -> String {
        let request = try makeRequest(path: "/api/auth/dev-token", method: "POST")
        let data = try await perform(request)

        struct TokenResponse: Decodable {
            let token: String
        }

        do {
            let response = try decoder.decode(TokenResponse.self, from: data)
            return response.token
        } catch {
            throw APIError.decodingError(error)
        }
    }

    func fetchNotes() async throws -> [Note] {
        let request = try makeRequest(path: "/api/notes", method: "GET")
        let data = try await perform(request)

        do {
            return try decoder.decode([Note].self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    func createNote(title: String, content: String) async throws -> Note {
        struct CreateBody: Encodable {
            let title: String
            let content: String
        }

        let body = try encoder.encode(CreateBody(title: title, content: content))
        let request = try makeRequest(path: "/api/notes", method: "POST", body: body)
        let data = try await perform(request)

        do {
            return try decoder.decode(Note.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    func deleteNote(id: String) async throws {
        let request = try makeRequest(path: "/api/notes/\(id)", method: "DELETE")
        _ = try await perform(request)
    }
}
