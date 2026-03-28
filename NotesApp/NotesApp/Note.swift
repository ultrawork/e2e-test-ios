import Foundation

/// Модель заметки, соответствующая backend API контракту.
struct Note: Identifiable, Codable {
    let id: String
    let text: String

    enum CodingKeys: String, CodingKey {
        case id
        case text = "content"
    }

    init(id: String = UUID().uuidString, text: String) {
        self.id = id
        self.text = text
    }
}

/// Структура запроса для создания заметки (POST /api/notes).
struct CreateNoteRequest: Codable {
    let content: String
}
