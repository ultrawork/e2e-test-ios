import Foundation

struct Note: Identifiable, Decodable {
    let id: String
    let title: String
    let content: String
    let isFavorited: Bool
    let categories: [Category]
    let createdAt: Date
    let updatedAt: Date

    private enum CodingKeys: String, CodingKey {
        case id, title, content, isFavorited, categories, createdAt, updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        content = try container.decode(String.self, forKey: .content)
        isFavorited = try container.decodeIfPresent(Bool.self, forKey: .isFavorited) ?? false
        categories = try container.decodeIfPresent([Category].self, forKey: .categories) ?? []
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
}
