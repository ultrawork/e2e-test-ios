import Foundation

/// Ошибки API-сервиса.
enum APIError: Error {
    case unauthorized
    case networkError(Error)
    case decodingError
}

/// Протокол API-сервиса для инъекции зависимостей.
protocol APIServiceProtocol {
    func fetchNotes() async throws -> [Note]
}

/// Сервис для работы с REST API заметок.
final class APIService: APIServiceProtocol {
    private let baseURL: String
    private let session: URLSession

    init(baseURL: String? = nil, session: URLSession = .shared) {
        self.baseURL = baseURL
            ?? (Bundle.main.infoDictionary?["BASE_URL"] as? String ?? "")
        self.session = session
    }

    func fetchNotes() async throws -> [Note] {
        let token = UserDefaults.standard.string(forKey: "token") ?? ""

        guard let url = URL(string: "\(baseURL)/notes") else {
            throw APIError.networkError(URLError(.badURL))
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }

        if let httpResponse = response as? HTTPURLResponse,
           httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }

        do {
            return try JSONDecoder().decode([Note].self, from: data)
        } catch {
            throw APIError.decodingError
        }
    }
}
