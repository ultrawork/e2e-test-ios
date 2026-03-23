import Foundation

/// Ошибки сетевого слоя.
enum APIError: Error, LocalizedError {
    case invalidBaseURL
    case invalidURL
    case unauthorized
    case notFound
    case serverError(Int, String?)
    case decodingError(Error)
    case encodingError(Error)
    case transportError(Error)
    case invalidResponse
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidBaseURL:
            return "Некорректный базовый URL"
        case .invalidURL:
            return "Некорректный URL запроса"
        case .unauthorized:
            return "Ошибка авторизации"
        case .notFound:
            return "Ресурс не найден"
        case .serverError(let code, let message):
            return "Ошибка сервера (\(code)): \(message ?? "неизвестная ошибка")"
        case .decodingError:
            return "Ошибка декодирования данных"
        case .encodingError:
            return "Ошибка кодирования данных"
        case .transportError:
            return "Ошибка сети"
        case .invalidResponse:
            return "Некорректный ответ сервера"
        case .unknown:
            return "Неизвестная ошибка"
        }
    }
}

/// Протокол сетевого сервиса для работы с заметками.
protocol APIServiceProtocol {
    func fetchNotes() async throws -> [Note]
    func createNote(title: String, content: String) async throws -> Note
    func deleteNote(id: String) async throws
}

/// Реализация сетевого сервиса на URLSession.
final class APIService: APIServiceProtocol {
    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let tokenProvider: (() -> String?)?

    init(
        session: URLSession = .shared,
        tokenProvider: (() -> String?)? = nil
    ) {
        let baseURLString = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String
            ?? "http://localhost:3000"
        self.baseURL = URL(string: baseURLString) ?? URL(string: "http://localhost:3000")!
        self.session = session
        self.tokenProvider = tokenProvider

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder
    }

    // MARK: - APIServiceProtocol

    func fetchNotes() async throws -> [Note] {
        let data = try await makeRequest(path: "/api/notes", method: "GET")
        do {
            return try decoder.decode([Note].self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    func createNote(title: String, content: String) async throws -> Note {
        let body: [String: String] = ["title": title, "content": content]
        let bodyData: Data
        do {
            bodyData = try encoder.encode(body)
        } catch {
            throw APIError.encodingError(error)
        }
        let data = try await makeRequest(path: "/api/notes", method: "POST", bodyData: bodyData)
        do {
            return try decoder.decode(Note.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    func deleteNote(id: String) async throws {
        _ = try await makeRequest(path: "/api/notes/\(id)", method: "DELETE")
    }

    // MARK: - Private

    private func makeRequest(path: String, method: String, bodyData: Data? = nil) async throws -> Data {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw APIError.invalidBaseURL
        }
        components.path = path
        guard let url = components.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method

        if method == "POST" || method == "DELETE" {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        if let token = tokenProvider?() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let bodyData = bodyData {
            request.httpBody = bodyData
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.transportError(error)
        }

        try validate(response: response, data: data)
        return data
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401:
            throw APIError.unauthorized
        case 404:
            throw APIError.notFound
        case 400...499, 500...599:
            let body = String(data: data, encoding: .utf8)
            throw APIError.serverError(httpResponse.statusCode, body)
        default:
            throw APIError.unknown
        }
    }
}
