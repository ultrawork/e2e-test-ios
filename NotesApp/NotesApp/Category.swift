import Foundation

struct Category: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let color: String
    let createdAt: Date
}
