import Foundation

struct Note: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let content: String
    let userId: String?
    let createdAt: Date
    let updatedAt: Date
    let categories: [Category]
    var isFavorited: Bool = false

    enum CodingKeys: String, CodingKey {
        case id, title, content, userId, createdAt, updatedAt, categories
    }
}
