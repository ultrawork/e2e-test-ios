import Foundation

/// Errors from the API layer
enum APIError: Error, LocalizedError {
    case unauthorized
    case serverError(Int)
    case networkError(Error)
    case decodingError(Error)
    case invalidURL

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Unauthorized"
        case .serverError(let code):
            return "Server error: \(code)"
        case .networkError(let error):
            return error.localizedDescription
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        case .invalidURL:
            return "Invalid URL"
        }
    }
}

/// Service for communicating with the Notes backend API
final class APIService {

    /// Base URL resolved from environment, Info.plist, or default
    let baseURL: String

    init() {
        self.baseURL = ProcessInfo.processInfo.environment["BASE_URL"]
            ?? Bundle.main.infoDictionary?["BASE_URL"] as? String
            ?? "http://localhost:4000/api"
    }

    /// Read the dev-token from UserDefaults
    private var token: String? {
        UserDefaults.standard.string(forKey: "token")
    }

    /// Fetch all notes from the backend
    func fetchNotes() async throws -> [Note] {
        guard let url = URL(string: "\(baseURL)/notes") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError(URLError(.badServerResponse))
        }

        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.serverError(httpResponse.statusCode)
        }

        do {
            return try JSONDecoder().decode([Note].self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    /// Create a new note via POST /api/notes
    func createNote(content: String) async throws -> Note {
        guard let url = URL(string: "\(baseURL)/notes") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let body = ["content": content]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError(URLError(.badServerResponse))
        }

        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.serverError(httpResponse.statusCode)
        }

        do {
            return try JSONDecoder().decode(Note.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    /// Delete a note via DELETE /api/notes/:id
    func deleteNote(id: String) async throws {
        guard let url = URL(string: "\(baseURL)/notes/\(id)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (_, response): (Data, URLResponse)
        do {
            (_, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError(URLError(.badServerResponse))
        }

        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.serverError(httpResponse.statusCode)
        }
    }
}
