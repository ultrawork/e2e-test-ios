import Foundation

/// Errors returned by APIService.
enum APIError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case serverError(Int)
    case decodingError(Error)
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Неверный URL сервера"
        case .networkError(let error):
            return "Сетевая ошибка: \(error.localizedDescription)"
        case .serverError(let code):
            return "Ошибка сервера: \(code)"
        case .decodingError:
            return "Ошибка обработки данных"
        case .unknown:
            return "Неизвестная ошибка"
        }
    }
}

/// Protocol for notes API operations.
protocol APIServiceProtocol {
    func fetchNotes() async throws -> [Note]
    func createNote(title: String, content: String) async throws -> Note
    func deleteNote(id: String) async throws
}

/// URLSession-based implementation of APIServiceProtocol.
final class APIService: APIServiceProtocol {
    static let shared = APIService()

    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder

    init(baseURL: URL? = nil, session: URLSession = .shared) {
        let urlString = Bundle.main.infoDictionary?["API_BASE_URL"] as? String
            ?? "http://localhost:3000/api"
        self.baseURL = baseURL ?? URL(string: urlString)!
        self.session = session
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
    }

    func fetchNotes() async throws -> [Note] {
        let url = baseURL.appendingPathComponent("notes")
        do {
            let (data, response) = try await session.data(from: url)
            try validateResponse(response)
            do {
                return try decoder.decode([Note].self, from: data)
            } catch {
                throw APIError.decodingError(error)
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }

    func createNote(title: String, content: String) async throws -> Note {
        let url = baseURL.appendingPathComponent("notes")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: String] = ["title": title, "content": content]
        request.httpBody = try JSONEncoder().encode(body)
        do {
            let (data, response) = try await session.data(for: request)
            try validateResponse(response)
            do {
                return try decoder.decode(Note.self, from: data)
            } catch {
                throw APIError.decodingError(error)
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }

    func deleteNote(id: String) async throws {
        let url = baseURL.appendingPathComponent("notes/\(id)")
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        do {
            let (_, response) = try await session.data(for: request)
            try validateResponse(response)
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }

    private func validateResponse(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw APIError.unknown
        }
        guard (200...299).contains(http.statusCode) else {
            throw APIError.serverError(http.statusCode)
        }
    }
}
