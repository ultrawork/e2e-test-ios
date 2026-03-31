import Foundation

struct Note: Identifiable, Codable {
    let id: String
    let text: String

    /// Initialize locally (no API)
    init(text: String) {
        self.id = UUID().uuidString
        self.text = text
    }

    enum CodingKeys: String, CodingKey {
        case id
        case text = "content"
    }
}
