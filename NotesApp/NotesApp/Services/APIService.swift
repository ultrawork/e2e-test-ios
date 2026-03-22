import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case httpError(Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .httpError(let code):
            return "HTTP error \(code)"
        }
    }
}

final class APIService {
    static let shared = APIService()

    private let baseURL: String
    private let decoder: JSONDecoder

    private init() {
        baseURL = Bundle.main.infoDictionary?["API_BASE_URL"] as? String ?? "http://127.0.0.1:4000"
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    func fetchNotes() async throws -> [Note] {
        let url = try makeURL("/api/notes")
        let (data, response) = try await URLSession.shared.data(from: url)
        try validate(response)
        return try decoder.decode([Note].self, from: data)
    }

    func createNote(title: String, content: String) async throws -> Note {
        let url = try makeURL("/api/notes")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["title": title, "content": content])
        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response)
        return try decoder.decode(Note.self, from: data)
    }

    func deleteNote(id: String) async throws {
        let url = try makeURL("/api/notes/\(id)")
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        let (_, response) = try await URLSession.shared.data(for: request)
        try validate(response)
    }

    func toggleFavorite(id: String) async throws -> Note {
        let url = try makeURL("/api/notes/\(id)/favorite")
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response)
        return try decoder.decode(Note.self, from: data)
    }

    private func makeURL(_ path: String) throws -> URL {
        guard let url = URL(string: baseURL + path) else {
            throw APIError.invalidURL
        }
        return url
    }

    private func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse,
              !(200...299).contains(http.statusCode) else {
            return
        }
        throw APIError.httpError(http.statusCode)
    }
}
