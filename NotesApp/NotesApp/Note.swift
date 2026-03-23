import Foundation

struct Note: Identifiable, Codable {
    let id: String
    let title: String
    let content: String
    let isFavorited: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case content
        case isFavorited
    }

    init(id: String = UUID().uuidString, title: String, content: String, isFavorited: Bool? = nil) {
        self.id = id
        self.title = title
        self.content = content
        self.isFavorited = isFavorited
    }
}
