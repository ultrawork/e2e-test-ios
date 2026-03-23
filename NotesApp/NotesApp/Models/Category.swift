import Foundation

/// Модель категории заметки.
struct Category: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let color: String
    let createdAt: Date
}
