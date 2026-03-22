// Category.swift
// NotesApp
//
// JSON example:
// {
//   "id": "cat-1",
//   "name": "Work",
//   "color": "#FFAA00"
// }

import Foundation

/// Категория заметки.
struct Category: Codable, Identifiable, Equatable {
    /// Строковый идентификатор категории.
    let id: String
    /// Название категории.
    let name: String
    /// HEX-цвет категории (например, "#FFAA00").
    /// Парсинг в Color/UIColor будет добавлен в отдельной задаче.
    let color: String
}
