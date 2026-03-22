// Note.swift
// NotesApp
//
// JSON example (ISO 8601):
// {
//   "id": "note-1",
//   "title": "Buy milk",
//   "content": "2% milk, one liter",
//   "categories": [
//     {
//       "id": "cat-1",
//       "name": "Groceries",
//       "color": "#00AAFF"
//     }
//   ],
//   "createdAt": "2024-03-10T12:34:56Z",
//   "updatedAt": "2024-03-10T13:00:00Z"
// }
//
// Сериализация дат ожидается через ISO8601DateFormatter
// на уровне JSONDecoder в слое API (будущие задачи).

import Foundation

/// Модель заметки.
struct Note: Codable, Identifiable, Equatable {
    /// Строковый идентификатор заметки.
    let id: String
    /// Заголовок заметки.
    let title: String
    /// Содержимое заметки.
    let content: String
    /// Список категорий заметки.
    let categories: [Category]
    /// Дата создания.
    let createdAt: Date
    /// Дата последнего обновления.
    let updatedAt: Date
}
