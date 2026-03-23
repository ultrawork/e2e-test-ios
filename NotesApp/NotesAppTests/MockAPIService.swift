import Foundation
@testable import NotesApp

/// Мок API-сервиса для unit-тестов.
final class MockAPIService: APIServiceProtocol {
    var fetchNotesResult: Result<[Note], Error> = .success([])
    var createNoteResult: Result<Note, Error>?
    var deleteNoteResult: Result<Void, Error> = .success(())

    var fetchNotesCalled = false
    var createNoteCalledWith: (title: String, content: String)?
    var deleteNoteCalledWith: String?

    func fetchNotes() async throws -> [Note] {
        fetchNotesCalled = true
        return try fetchNotesResult.get()
    }

    func createNote(title: String, content: String) async throws -> Note {
        createNoteCalledWith = (title, content)
        if let result = createNoteResult {
            return try result.get()
        }
        return makeNote(id: UUID().uuidString, title: title, content: content)
    }

    func deleteNote(id: String) async throws {
        deleteNoteCalledWith = id
        try deleteNoteResult.get()
    }

    func toggleFavorite(note: Note) -> Note {
        var updated = note
        updated.isFavorited.toggle()
        return updated
    }

    /// Фабрика тестовой заметки.
    static func makeNote(
        id: String = "test-id",
        title: String = "Test",
        content: String = "Test content",
        userId: String = "user-1"
    ) -> Note {
        Note(
            id: id,
            title: title,
            content: content,
            userId: userId,
            createdAt: Date(),
            updatedAt: Date(),
            categories: []
        )
    }
}

private func makeNote(id: String, title: String, content: String) -> Note {
    MockAPIService.makeNote(id: id, title: title, content: content)
}
