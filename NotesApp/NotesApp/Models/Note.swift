import Foundation

/// Модель заметки, соответствующая API-контракту.
struct Note: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let content: String
    let userId: String?
    let createdAt: Date
    let updatedAt: Date
    let categories: [Category]

    /// Локальное поле избранного, не участвует в кодировании/декодировании.
    var isFavorited: Bool = false

    enum CodingKeys: String, CodingKey {
        case id, title, content, userId, createdAt, updatedAt, categories
    }
}
