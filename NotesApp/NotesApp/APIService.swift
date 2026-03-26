import Foundation

/// Errors returned by the API layer.
enum APIError: Error {
    case unauthorized
    case notFound
    case serverError(Int)
    case decodingError(Error)
    case transportError(Error)
}

/// Protocol describing the notes API surface.
protocol APIServiceProtocol {
    func fetchNotes() async throws -> [Note]
    func createNote(title: String, content: String) async throws -> Note
    func deleteNote(id: String) async throws
}

/// Concrete API service backed by URLSession.
final class APIService: APIServiceProtocol {
    private let session: URLSession

    private var baseURL: String {
        (Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String) ?? "http://localhost:3000/api"
    }

    private var token: String? {
        UserDefaults.standard.string(forKey: "token")
    }

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - APIServiceProtocol

    func fetchNotes() async throws -> [Note] {
        let request = try makeRequest(path: "/notes", method: "GET")
        let (data, response) = try await perform(request)
        try validateResponse(response)
        return try makeDecoder().decode([Note].self, from: data)
    }

    func createNote(title: String, content: String) async throws -> Note {
        let body: [String: String] = ["title": title, "content": content]
        let bodyData = try JSONSerialization.data(withJSONObject: body)
        var request = try makeRequest(path: "/notes", method: "POST")
        request.httpBody = bodyData
        let (data, response) = try await perform(request)
        try validateResponse(response)
        return try makeDecoder().decode(Note.self, from: data)
    }

    func deleteNote(id: String) async throws {
        let request = try makeRequest(path: "/notes/\(id)", method: "DELETE")
        let (_, response) = try await perform(request)
        try validateResponse(response)
    }

    // MARK: - Private helpers

    private func makeRequest(path: String, method: String) throws -> URLRequest {
        guard let url = URL(string: baseURL + path) else {
            throw APIError.transportError(URLError(.badURL))
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    private func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    private func perform(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch {
            throw APIError.transportError(error)
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
        case 500...599:
            throw APIError.serverError(http.statusCode)
        default:
            throw APIError.serverError(http.statusCode)
        }
    }
}
