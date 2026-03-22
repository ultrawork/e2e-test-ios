import Foundation

struct Category: Identifiable, Decodable {
    let id: String
    let name: String
    let color: String
    let createdAt: Date
}
