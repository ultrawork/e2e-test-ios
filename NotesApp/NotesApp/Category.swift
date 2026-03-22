import Foundation

/// Модель категории заметки
struct Category: Identifiable, Codable {
    let id: String
    let name: String
    let color: String
    let createdAt: String
}
