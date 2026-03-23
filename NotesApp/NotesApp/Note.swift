import Foundation

/// Категория заметки, полученная от API.
struct Category: Identifiable, Codable {
    let id: String
    let name: String
    let color: String
    let createdAt: Date
}

/// Заметка, соответствующая API-контракту.
struct Note: Identifiable, Codable {
    let id: String
    let title: String
    let content: String
    let userId: String
    let createdAt: Date
    let updatedAt: Date
    let categories: [Category]

    /// Клиентское поле — не участвует в JSON encode/decode.
    var isFavorited: Bool = false

    enum CodingKeys: String, CodingKey {
        case id, title, content, userId, createdAt, updatedAt, categories
    }
}
