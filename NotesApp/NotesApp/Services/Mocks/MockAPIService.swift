import Foundation

/// In-memory mock implementation of APIServiceProtocol for previews and offline usage.
final class MockAPIService: APIServiceProtocol {
    private var categories: [Category]

    init() {
        let now = ISO8601DateFormatter().string(from: Date())
        self.categories = [
            Category(id: UUID().uuidString, name: "Work", color: "#4A90D9", createdAt: now),
            Category(id: UUID().uuidString, name: "Personal", color: "#E57373", createdAt: now)
        ]
    }

    func fetchCategories() async throws -> [Category] {
        categories
    }

    func createCategory(name: String, colorHex: String) async throws -> Category {
        let category = Category(
            id: UUID().uuidString,
            name: name,
            color: colorHex,
            createdAt: ISO8601DateFormatter().string(from: Date())
        )
        categories.append(category)
        return category
    }

    func updateCategory(id: String, name: String?, colorHex: String?) async throws -> Category {
        guard let index = categories.firstIndex(where: { $0.id == id }) else {
            throw APIError.httpError(statusCode: 404, data: nil)
        }
        if let name = name {
            categories[index].name = name
        }
        if let colorHex = colorHex {
            categories[index].color = colorHex
        }
        return categories[index]
    }

    func deleteCategory(id: String) async throws {
        guard let index = categories.firstIndex(where: { $0.id == id }) else {
            throw APIError.httpError(statusCode: 404, data: nil)
        }
        categories.remove(at: index)
    }
}
