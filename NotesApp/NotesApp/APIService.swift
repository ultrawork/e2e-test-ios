import Foundation

/// Ошибки API-сервиса.
enum APIError: Error {
    case unauthorized
    case networkError(Error)
    case decodingError(Error)
    case notFound
}

/// Протокол API-сервиса для работы с заметками.
protocol APIServiceProtocol {
    func fetchNotes() async throws -> [Note]
    func createNote(text: String) async throws -> Note
    func deleteNote(id: String) async throws
}

/// Реализация API-сервиса, читающая BASE_URL и DEV_TOKEN из Info.plist.
final class APIService: APIServiceProtocol {
    private let baseURL: String
    private let token: String
    private let session: URLSession
    private let decoder: JSONDecoder

    init() {
        let env = ProcessInfo.processInfo.environment
        let info = Bundle.main.infoDictionary
        self.baseURL = env["BASE_URL"]
            ?? (info?["BASE_URL"] as? String)
            ?? "http://localhost:4000"
        let rawToken = env["DEV_TOKEN"]
            ?? (info?["DEV_TOKEN"] as? String)
            ?? "dev_token_placeholder"
        self.token = rawToken.isEmpty ? "dev_token_placeholder" : rawToken
        self.session = URLSession.shared
        self.decoder = JSONDecoder()
    }

    // MARK: - APIServiceProtocol

    func fetchNotes() async throws -> [Note] {
        let request = try makeRequest(path: "/api/notes", method: "GET")
        let (data, response) = try await perform(request)
        try validate(response)
        do {
            return try decoder.decode([Note].self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    func createNote(text: String) async throws -> Note {
        let body = try JSONEncoder().encode(CreateNoteRequest(content: text))
        let request = try makeRequest(path: "/api/notes", method: "POST", body: body)
        let (data, response) = try await perform(request)
        try validate(response)
        do {
            return try decoder.decode(Note.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    func deleteNote(id: String) async throws {
        let request = try makeRequest(path: "/api/notes/\(id)", method: "DELETE")
        let (_, response) = try await perform(request)
        try validate(response)
    }

    // MARK: - Private

    private func makeRequest(path: String, method: String, body: Data? = nil) throws -> URLRequest {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw APIError.networkError(URLError(.badURL))
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        return request
    }

    private func perform(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError(URLError(.badServerResponse))
        }
        return (data, httpResponse)
    }

    private func validate(_ response: HTTPURLResponse) throws {
        switch response.statusCode {
        case 200...299:
            return
        case 401:
            throw APIError.unauthorized
        case 404:
            throw APIError.notFound
        default:
            throw APIError.networkError(URLError(.badServerResponse))
        }
    }
}
