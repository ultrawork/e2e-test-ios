import Foundation

struct Note: Identifiable, Codable {
    let id: String
    let title: String
    let content: String
    let createdAt: String
    let updatedAt: String
}
