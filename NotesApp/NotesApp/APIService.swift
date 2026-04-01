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
        let raw = ProcessInfo.processInfo.environment["BACKEND_BASE_URL"]
            ?? ProcessInfo.processInfo.environment["BASE_URL"]
            ?? Bundle.main.infoDictionary?["BACKEND_BASE_URL"] as? String
            ?? Bundle.main.infoDictionary?["BASE_URL"] as? String
            ?? "http://localhost:4000/api"
        // Normalize: strip trailing slash
        if raw.hasSuffix("/") {
            self.baseURL = String(raw.dropLast())
        } else {
            self.baseURL = raw
        }
    }

    /// Read the dev-token from UserDefaults
    private var token: String? {
        UserDefaults.standard.string(forKey: "token")
    }

    /// Build a URLRequest with common headers
    private func makeRequest(path: String, method: String, body: Data? = nil) throws -> URLRequest {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body = body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = body
        }
        return request
    }

    /// Validate HTTP response status, throwing appropriate APIError
    private func validateResponse(_ response: URLResponse) throws -> HTTPURLResponse {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError(URLError(.badServerResponse))
        }
        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.serverError(httpResponse.statusCode)
        }
        return httpResponse
    }

    /// Fetch all notes from the backend
    func fetchNotes() async throws -> [Note] {
        let request = try makeRequest(path: "/notes", method: "GET")

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }

        _ = try validateResponse(response)

        do {
            return try JSONDecoder().decode([Note].self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    /// Create a new note via POST /notes
    func createNote(content: String) async throws -> Note {
        let body = try JSONSerialization.data(withJSONObject: ["content": content])
        let request = try makeRequest(path: "/notes", method: "POST", body: body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }

        _ = try validateResponse(response)

        do {
            return try JSONDecoder().decode(Note.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    /// Delete a note via DELETE /notes/:id
    func deleteNote(id: String) async throws {
        let request = try makeRequest(path: "/notes/\(id)", method: "DELETE")

        let (_, response): (Data, URLResponse)
        do {
            (_, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }

        _ = try validateResponse(response)
    }
}
