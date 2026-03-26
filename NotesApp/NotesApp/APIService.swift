import Foundation

/// Domain-specific API errors.
enum APIError: Error, Equatable {
    case unauthorized
    case networkError(String)
    case decodingError(String)
    case unknown(Int)

    static func == (lhs: APIError, rhs: APIError) -> Bool {
        switch (lhs, rhs) {
        case (.unauthorized, .unauthorized):
            return true
        case (.networkError(let a), .networkError(let b)):
            return a == b
        case (.decodingError(let a), .decodingError(let b)):
            return a == b
        case (.unknown(let a), .unknown(let b)):
            return a == b
        default:
            return false
        }
    }
}

/// Protocol for dependency injection and testability.
protocol APIServiceProtocol {
    func fetchNotes() async throws -> [Note]
    func createNote(title: String, content: String) async throws -> Note
    func deleteNote(id: String) async throws
}

/// Production networking layer for the Notes API.
final class APIService: APIServiceProtocol {
    private let session: URLSession
    private let baseURL: String

    init(session: URLSession = .shared) {
        self.session = session
        self.baseURL = Bundle.main.infoDictionary?["API_BASE_URL"] as? String ?? "http://localhost:3000"
    }

    private var token: String? {
        UserDefaults.standard.string(forKey: "jwtToken")
    }

    private func makeRequest(path: String, method: String, body: Data? = nil) -> URLRequest {
        let url = URL(string: "\(baseURL)\(path)")!
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.timeoutInterval = 2
        request.httpBody = body
        return request
    }

    private func validateResponse(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw APIError.unknown(0)
        }
        if http.statusCode == 401 {
            throw APIError.unauthorized
        }
        if !(200..<300).contains(http.statusCode) {
            throw APIError.unknown(http.statusCode)
        }
    }

    func fetchNotes() async throws -> [Note] {
        let request = makeRequest(path: "/api/notes", method: "GET")
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.networkError(error.localizedDescription)
        }
        try validateResponse(response)
        do {
            return try JSONDecoder().decode([Note].self, from: data)
        } catch {
            throw APIError.decodingError(error.localizedDescription)
        }
    }

    func createNote(title: String, content: String) async throws -> Note {
        let body = try JSONEncoder().encode(["title": title, "content": content])
        let request = makeRequest(path: "/api/notes", method: "POST", body: body)
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.networkError(error.localizedDescription)
        }
        try validateResponse(response)
        do {
            return try JSONDecoder().decode(Note.self, from: data)
        } catch {
            throw APIError.decodingError(error.localizedDescription)
        }
    }

    func deleteNote(id: String) async throws {
        let request = makeRequest(path: "/api/notes/\(id)", method: "DELETE")
        let response: URLResponse
        do {
            (_, response) = try await session.data(for: request)
        } catch {
            throw APIError.networkError(error.localizedDescription)
        }
        try validateResponse(response)
    }
}
