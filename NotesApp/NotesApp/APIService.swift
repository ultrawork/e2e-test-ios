import Foundation

/// Ошибки API-сервиса.
enum APIError: LocalizedError {
    case network(Error)
    case badResponse(Int)
    case unauthorized
    case decodingError(Error)
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .network(let error):
            return "Ошибка сети: \(error.localizedDescription)"
        case .badResponse(let code):
            return "Ошибка сервера: \(code)"
        case .unauthorized:
            return "Не авторизован"
        case .decodingError(let error):
            return "Ошибка декодирования: \(error.localizedDescription)"
        case .serverError(let message):
            return message
        }
    }
}

/// Сервис для работы с API заметок.
final class APIService {
    private let baseURL = "http://localhost:3000"
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    private func getToken() -> String? {
        UserDefaults.standard.string(forKey: "jwtToken")
    }

    #if DEBUG
    /// Запрашивает dev-токен и сохраняет в UserDefaults.
    private func fetchDevToken() async throws {
        guard let url = URL(string: "\(baseURL)/api/auth/dev-token") else {
            throw APIError.serverError("Invalid dev-token URL")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.badResponse((response as? HTTPURLResponse)?.statusCode ?? 0)
        }

        struct TokenResponse: Decodable {
            let token: String
        }

        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        UserDefaults.standard.set(tokenResponse.token, forKey: "jwtToken")
    }
    #endif

    /// Проверяет наличие токена; в Debug-режиме запрашивает dev-токен при отсутствии.
    private func ensureToken() async throws {
        #if DEBUG
        if getToken() == nil {
            try await fetchDevToken()
        }
        #endif
    }

    /// Общий метод выполнения HTTP-запроса с авторизацией.
    private func performRequest(_ path: String, method: String, body: Data? = nil) async throws -> (Data, HTTPURLResponse) {
        try await ensureToken()

        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw APIError.serverError("Некорректный URL")
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = getToken() {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            urlRequest.httpBody = body
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch {
            throw APIError.network(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.serverError("Некорректный ответ сервера")
        }

        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.badResponse(httpResponse.statusCode)
        }

        return (data, httpResponse)
    }

    /// Универсальный метод запроса к API с декодированием ответа.
    private func request<T: Decodable>(_ path: String, method: String, body: Data? = nil) async throws -> T {
        let (data, _) = try await performRequest(path, method: method, body: body)
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    /// Запрос без возвращаемого тела (для DELETE).
    private func requestVoid(_ path: String, method: String) async throws {
        _ = try await performRequest(path, method: method)
    }

    /// Получает список заметок.
    func fetchNotes() async throws -> [Note] {
        try await request("/api/notes", method: "GET")
    }

    /// Создаёт новую заметку.
    func createNote(title: String, content: String) async throws -> Note {
        let body = try JSONEncoder().encode(["title": title, "content": content])
        return try await request("/api/notes", method: "POST", body: body)
    }

    /// Удаляет заметку по ID.
    func deleteNote(id: String) async throws {
        try await requestVoid("/api/notes/\(id)", method: "DELETE")
    }
}
