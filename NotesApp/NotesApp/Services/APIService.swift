import Foundation

// MARK: - Developer Notes
//
// APIService reads the base URL from Info.plist key `API_BASE_URL`.
// Default value (if the key is missing): http://127.0.0.1:4000
// For the iOS Simulator this default is sufficient — just run the backend
// locally on port 4000. For a physical device, set the key to your
// machine's LAN IP (e.g. http://192.168.1.42:4000).
//
// NSAppTransportSecurity / NSAllowsArbitraryLoads is enabled in Info.plist
// to allow plain HTTP connections during development.

/// Errors produced by ``APIService`` network operations.
enum APIError: Error, LocalizedError {
    /// The constructed URL is invalid.
    case invalidURL
    /// The server returned a non-2xx HTTP status code.
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

/// Singleton service responsible for all REST API communication with the notes backend.
///
/// Base URL is read from `Info.plist` key `API_BASE_URL` (defaults to `http://127.0.0.1:4000`).
/// All responses are decoded with an ISO-8601 date strategy.
final class APIService {
    /// Shared singleton instance.
    static let shared = APIService()

    private let baseURL: String
    private let decoder: JSONDecoder

    private init() {
        baseURL = Bundle.main.infoDictionary?["API_BASE_URL"] as? String ?? "http://127.0.0.1:4000"
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    /// Fetches all notes from the backend.
    /// - Returns: An array of ``Note`` objects.
    /// - Throws: ``APIError`` on network or decoding failure.
    func fetchNotes() async throws -> [Note] {
        let url = try makeURL("/api/notes")
        let (data, response) = try await URLSession.shared.data(from: url)
        try validate(response)
        return try decoder.decode([Note].self, from: data)
    }

    /// Creates a new note on the backend.
    /// - Parameters:
    ///   - title: The title of the new note.
    ///   - content: The body content of the new note.
    /// - Returns: The created ``Note`` as returned by the server.
    /// - Throws: ``APIError`` on network or decoding failure.
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

    /// Deletes a note by its identifier.
    /// - Parameter id: The unique identifier of the note to delete.
    /// - Throws: ``APIError`` on network failure or non-2xx response.
    func deleteNote(id: String) async throws {
        let url = try makeURL("/api/notes/\(id)")
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        let (_, response) = try await URLSession.shared.data(for: request)
        try validate(response)
    }

    /// Toggles the favorite status of a note.
    /// - Parameter id: The unique identifier of the note.
    /// - Returns: The updated ``Note`` with the new favorite state.
    /// - Throws: ``APIError`` on network or decoding failure.
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
