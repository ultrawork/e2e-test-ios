import Foundation

struct Note: Codable, Identifiable {
    let id: String
    let title: String
    let content: String
    let createdAt: Date
    let updatedAt: Date
    let userId: String?
    let categories: [Category]
    var isFavorited: Bool = false

    enum CodingKeys: String, CodingKey {
        case id, title, content, createdAt, updatedAt, userId, categories
    }

    init(id: String, title: String, content: String, createdAt: Date, updatedAt: Date, userId: String?, categories: [Category], isFavorited: Bool = false) {
        self.id = id
        self.title = title
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.userId = userId
        self.categories = categories
        self.isFavorited = isFavorited
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        content = try container.decode(String.self, forKey: .content)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        userId = try container.decodeIfPresent(String.self, forKey: .userId)
        categories = try container.decodeIfPresent([Category].self, forKey: .categories) ?? []
        isFavorited = false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(content, forKey: .content)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(userId, forKey: .userId)
        try container.encode(categories, forKey: .categories)
    }
}
