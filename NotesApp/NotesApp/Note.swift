import Foundation

struct Note: Identifiable, Codable {
    let id: String
    let text: String

    enum CodingKeys: String, CodingKey {
        case id
        case text = "content"
    }

    init(id: String = UUID().uuidString, text: String) {
        self.id = id
        self.text = text
    }
}
