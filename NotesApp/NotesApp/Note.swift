import Foundation

/// Модель заметки с поддержкой backend API
struct Note: Identifiable, Codable {
    let id: String
    let title: String
    let content: String
    let userId: String
    let createdAt: String
    let updatedAt: String
    let categories: [Category]
    var isFavorited: Bool = false

    enum CodingKeys: String, CodingKey {
        case id, title, content, userId, createdAt, updatedAt, categories
    }
}
