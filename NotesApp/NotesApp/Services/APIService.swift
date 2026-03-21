import Foundation

// MARK: - APIServiceProtocol

/// Protocol defining CRUD operations for categories.
protocol APIServiceProtocol {
    func fetchCategories() async throws -> [Category]
    func createCategory(name: String, colorHex: String) async throws -> Category
    func updateCategory(id: String, name: String?, colorHex: String?) async throws -> Category
    func deleteCategory(id: String) async throws
}

// MARK: - HTTPMethod

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

// MARK: - APIError

/// Errors produced by APIService.
enum APIError: Error, LocalizedError {
    case invalidBaseURL
    case invalidURL(String)
    case requestFailed(underlying: Error)
    case httpError(statusCode: Int, data: Data?)
    case decodingError(underlying: Error)
    case encodingError(underlying: Error)
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .invalidBaseURL:
            return "Invalid base URL configuration."
        case .invalidURL(let path):
            return "Cannot construct URL for path: \(path)."
        case .requestFailed(let underlying):
            return "Network request failed: \(underlying.localizedDescription)"
        case .httpError(let statusCode, _):
            return "HTTP error with status code \(statusCode)."
        case .decodingError(let underlying):
            return "Failed to decode response: \(underlying.localizedDescription)"
        case .encodingError(let underlying):
            return "Failed to encode request body: \(underlying.localizedDescription)"
        case .emptyResponse:
            return "Empty response received."
        }
    }
}

// MARK: - Request DTOs

struct CreateCategoryRequest: Encodable {
    let name: String
    let color: String
}

struct UpdateCategoryRequest: Encodable {
    let name: String?
    let color: String?
}

// MARK: - APIService

/// URLSession-based implementation of APIServiceProtocol.
final class APIService: APIServiceProtocol {
    static let shared = APIService()

    private let session: URLSession
    private let baseURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    /// Creates an APIService instance.
    /// - Parameters:
    ///   - session: URLSession to use for requests.
    ///   - baseURL: Override base URL. Falls back to `API_BASE_URL` env var, then `http://localhost:3000`.
    init(session: URLSession = .shared, baseURL: URL? = nil) {
        self.session = session

        if let baseURL = baseURL {
            self.baseURL = baseURL
        } else {
            let envURL = ProcessInfo.processInfo.environment["API_BASE_URL"] ?? "http://localhost:3000"
            self.baseURL = URL(string: envURL) ?? URL(string: "http://localhost:3000")!
        }

        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        self.encoder = enc

        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        self.decoder = dec
    }

    // MARK: - Generic Request

    /// Performs a network request and decodes the response.
    private func request<T: Decodable>(
        path: String,
        method: HTTPMethod,
        body: (any Encodable)? = nil,
        acceptableStatus: Range<Int> = 200..<300
    ) async throws -> T {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw APIError.invalidURL(path)
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")

        if let body = body {
            do {
                urlRequest.httpBody = try encoder.encode(AnyEncodable(body))
            } catch {
                throw APIError.encodingError(underlying: error)
            }
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch {
            throw APIError.requestFailed(underlying: error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.emptyResponse
        }

        guard acceptableStatus.contains(httpResponse.statusCode) else {
            throw APIError.httpError(statusCode: httpResponse.statusCode, data: data)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(underlying: error)
        }
    }

    /// Performs a network request that expects no response body (e.g. DELETE → 204).
    private func requestVoid(
        path: String,
        method: HTTPMethod,
        body: (any Encodable)? = nil,
        acceptableStatus: Range<Int> = 200..<300
    ) async throws {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw APIError.invalidURL(path)
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")

        if let body = body {
            do {
                urlRequest.httpBody = try encoder.encode(AnyEncodable(body))
            } catch {
                throw APIError.encodingError(underlying: error)
            }
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch {
            throw APIError.requestFailed(underlying: error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.emptyResponse
        }

        guard acceptableStatus.contains(httpResponse.statusCode) else {
            throw APIError.httpError(statusCode: httpResponse.statusCode, data: data)
        }
    }

    // MARK: - APIServiceProtocol

    func fetchCategories() async throws -> [Category] {
        try await request(path: "/api/categories", method: .get)
    }

    func createCategory(name: String, colorHex: String) async throws -> Category {
        let body = CreateCategoryRequest(name: name, color: colorHex)
        return try await request(path: "/api/categories", method: .post, body: body)
    }

    func updateCategory(id: String, name: String?, colorHex: String?) async throws -> Category {
        let body = UpdateCategoryRequest(name: name, color: colorHex)
        return try await request(path: "/api/categories/\(id)", method: .put, body: body)
    }

    func deleteCategory(id: String) async throws {
        try await requestVoid(path: "/api/categories/\(id)", method: .delete)
    }
}

// MARK: - AnyEncodable

/// Type-erasing wrapper for Encodable values.
private struct AnyEncodable: Encodable {
    private let encodeFunc: (Encoder) throws -> Void

    init(_ wrapped: any Encodable) {
        self.encodeFunc = { encoder in
            try wrapped.encode(to: encoder)
        }
    }

    func encode(to encoder: Encoder) throws {
        try encodeFunc(encoder)
    }
}
