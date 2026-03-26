import Foundation

struct Note: Identifiable, Codable {
    let id: Int
    let text: String

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case text = "text"
    }

    init(id: Int = Int.random(in: 1...999_999), text: String) {
        self.id = id
        self.text = text
    }
}
