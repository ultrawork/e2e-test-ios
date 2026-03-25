import Foundation

struct Note: Identifiable, Codable {
    let id: String
    var title: String
    var content: String
    let createdAt: Date
    let updatedAt: Date
    var categories: [Category]
    var isFavorited: Bool = false

    enum CodingKeys: String, CodingKey {
        case id, title, content, createdAt, updatedAt, categories
    }
}
