import Foundation

/// Represents a note from the backend API.
struct Note: Identifiable, Codable, Equatable {
    var id: String
    var title: String
    var content: String
    var userId: String?
    var createdAt: Date
    var updatedAt: Date
    var categories: [Category]
    var isFavorited: Bool = false

    enum CodingKeys: String, CodingKey {
        case id, title, content, userId, createdAt, updatedAt, categories
    }
}
