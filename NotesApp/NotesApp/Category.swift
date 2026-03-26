import Foundation

struct Category: Codable, Identifiable {
    let id: String
    let name: String
    let color: String
    let createdAt: Date
}
