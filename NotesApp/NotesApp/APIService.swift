import Foundation

/// Protocol defining the Notes API contract for testability.
protocol APIServiceProtocol {
    func fetchNotes() async throws -> [Note]
    func createNote(title: String, content: String) async throws -> Note
    func deleteNote(id: String) async throws
}

/// Service for communicating with the Notes REST API.
final class APIService: APIServiceProtocol {
    static let shared = APIService()

    private let baseURL: URL
    private let session: URLSession

    private convenience init() {
        let urlString = Bundle.main.infoDictionary?["API_BASE_URL"] as? String
            ?? "http://localhost:3000/api"
        guard let url = URL(string: urlString) else {
            fatalError("Invalid API_BASE_URL: \(urlString)")
        }
        self.init(baseURL: url, session: .shared)
    }

    /// Testable initializer accepting base URL and URLSession.
    init(baseURL: URL, session: URLSession) {
        self.baseURL = baseURL
        self.session = session
    }

    // MARK: - Public API

    /// Fetches all notes. Returns an empty array on 401 (unauthorized).
    func fetchNotes() async throws -> [Note] {
        let request = makeRequest(path: "/notes", method: "GET")
        let (data, response) = try await session.data(for: request)

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
            return []
        }

        return try JSONDecoder().decode([Note].self, from: data)
    }

    /// Creates a new note with the given title and content.
    func createNote(title: String, content: String) async throws -> Note {
        struct CreateBody: Encodable {
            let title: String
            let content: String
        }
        let body = CreateBody(title: title, content: content)
        let request = try makeRequest(path: "/notes", method: "POST", body: body)
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(Note.self, from: data)
    }

    /// Deletes the note with the given ID.
    func deleteNote(id: String) async throws {
        let request = makeRequest(path: "/notes/\(id)", method: "DELETE")
        let (_, _) = try await session.data(for: request)
    }

    // MARK: - Private

    private func makeRequest(path: String, method: String) -> URLRequest {
        let url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = method
        if let token = UserDefaults.standard.string(forKey: "token"), !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    private func makeRequest<T: Encodable>(path: String, method: String, body: T) throws -> URLRequest {
        var request = makeRequest(path: path, method: method)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        return request
    }
}
