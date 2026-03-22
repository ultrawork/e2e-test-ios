import Foundation

/// Ошибки API-сервиса
enum APIError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case serverError(Int)
    case notFound

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Некорректный URL"
        case .networkError(let error):
            return "Ошибка сети: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Ошибка декодирования: \(error.localizedDescription)"
        case .serverError(let code):
            return "Ошибка сервера: \(code)"
        case .notFound:
            return "Заметка не найдена"
        }
    }
}

/// Протокол API-сервиса для работы с заметками
protocol APIServiceProtocol {
    func fetchNotes() async throws -> [Note]
    func createNote(title: String, content: String) async throws -> Note
    func updateNote(id: String, title: String, content: String) async throws -> Note
    func deleteNote(id: String) async throws
}

/// Реальный API-сервис для работы с backend
final class APIService: APIServiceProtocol {
    static let shared = APIService()

    private let baseURL: String
    private let session: URLSession
    private let decoder: JSONDecoder

    init() {
        if let url = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String, !url.isEmpty {
            baseURL = url
        } else {
            baseURL = "http://localhost:3000"
        }
        session = URLSession.shared
        decoder = JSONDecoder()
    }

    func fetchNotes() async throws -> [Note] {
        guard let url = URL(string: "\(baseURL)/notes") else {
            throw APIError.invalidURL
        }
        do {
            let (data, response) = try await session.data(from: url)
            try validateResponse(response)
            return try decoder.decode([Note].self, from: data)
        } catch let error as APIError {
            throw error
        } catch let error as DecodingError {
            throw APIError.decodingError(error)
        } catch {
            throw APIError.networkError(error)
        }
    }

    func createNote(title: String, content: String) async throws -> Note {
        guard let url = URL(string: "\(baseURL)/notes") else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: String] = ["title": title, "content": content]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await session.data(for: request)
            try validateResponse(response)
            return try decoder.decode(Note.self, from: data)
        } catch let error as APIError {
            throw error
        } catch let error as DecodingError {
            throw APIError.decodingError(error)
        } catch {
            throw APIError.networkError(error)
        }
    }

    func updateNote(id: String, title: String, content: String) async throws -> Note {
        guard let url = URL(string: "\(baseURL)/notes/\(id)") else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: String] = ["title": title, "content": content]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await session.data(for: request)
            try validateResponse(response)
            return try decoder.decode(Note.self, from: data)
        } catch let error as APIError {
            throw error
        } catch let error as DecodingError {
            throw APIError.decodingError(error)
        } catch {
            throw APIError.networkError(error)
        }
    }

    func deleteNote(id: String) async throws {
        guard let url = URL(string: "\(baseURL)/notes/\(id)") else {
            throw APIError.invalidURL
        }
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
        guard let httpResponse = response as? HTTPURLResponse else { return }
        switch httpResponse.statusCode {
        case 200...299:
            return
        case 404:
            throw APIError.notFound
        default:
            throw APIError.serverError(httpResponse.statusCode)
        }
    }
}

/// Мок API-сервис для Preview и UI-тестов
final class MockAPIService: APIServiceProtocol {
    private var notes: [Note] = []

    func fetchNotes() async throws -> [Note] {
        return notes
    }

    func createNote(title: String, content: String) async throws -> Note {
        let note = Note(
            id: UUID().uuidString,
            title: title,
            content: content,
            userId: "mock-user",
            createdAt: ISO8601DateFormatter().string(from: Date()),
            updatedAt: ISO8601DateFormatter().string(from: Date()),
            categories: []
        )
        notes.append(note)
        return note
    }

    func updateNote(id: String, title: String, content: String) async throws -> Note {
        guard let index = notes.firstIndex(where: { $0.id == id }) else {
            throw APIError.notFound
        }
        let existing = notes[index]
        let updated = Note(
            id: id,
            title: title,
            content: content,
            userId: existing.userId,
            createdAt: existing.createdAt,
            updatedAt: ISO8601DateFormatter().string(from: Date()),
            categories: existing.categories
        )
        notes[index] = updated
        return updated
    }

    func deleteNote(id: String) async throws {
        notes.removeAll { $0.id == id }
    }
}
