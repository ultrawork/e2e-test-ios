import Foundation

/// Represents a note category from the backend API.
struct Category: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var color: String
    var createdAt: Date
}
