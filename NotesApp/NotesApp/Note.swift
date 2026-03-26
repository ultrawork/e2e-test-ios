import Foundation

struct Note: Identifiable, Codable {
    let id: String
    let title: String
    let content: String

    /// Alias for `title`, used by UI layer.
    var text: String { title }

    enum CodingKeys: String, CodingKey {
        case id, title, content
    }
}
