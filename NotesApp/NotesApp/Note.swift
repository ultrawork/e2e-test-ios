import Foundation

struct Note: Identifiable, Codable, Equatable {
    let id: String
    let text: String

    enum CodingKeys: String, CodingKey {
        case id
        case text = "content"
    }
}
