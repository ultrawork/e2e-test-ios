import Foundation

/// Errors returned by `APIService`.
enum APIError: Error, LocalizedError {
    case unauthorized
    case decodingError
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Unauthorized"
        case .decodingError:
            return "Failed to decode response"
        case .networkError(let error):
            return error.localizedDescription
        }
    }
}

/// Protocol for dependency injection in tests.
protocol APIServiceProtocol {
    func fetchNotes() async throws -> [Note]
}

/// Singleton network service that communicates with the backend API.
final class APIService: APIServiceProtocol {
    static let shared = APIService()

    private let baseURL: URL
    private let session: URLSession

    /// Testable initializer.
    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    /// Convenience initializer that reads `BASE_URL` from Info.plist.
    private convenience init() {
        let base: String
        if let plistValue = Bundle.main.infoDictionary?["BASE_URL"] as? String, !plistValue.isEmpty {
            base = plistValue
        } else {
            base = "http://localhost:3000"
        }
        let url = URL(string: "\(base)/api")!
        self.init(baseURL: url)
    }

    /// Fetches notes from GET /notes with Bearer token from UserDefaults.
    func fetchNotes() async throws -> [Note] {
        let url = baseURL.appendingPathComponent("notes")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        if let token = UserDefaults.standard.string(forKey: "token"), !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError(URLError(.badServerResponse))
        }

        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }

        do {
            return try JSONDecoder().decode([Note].self, from: data)
        } catch {
            throw APIError.decodingError
        }
    }
}
