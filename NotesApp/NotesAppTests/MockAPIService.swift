import Foundation
@testable import NotesApp

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
        return Note(
            id: UUID().uuidString,
            title: title,
            content: content,
            userId: nil,
            createdAt: Date(),
            updatedAt: Date(),
            categories: []
        )
    }

    func deleteNote(id: String) async throws {
        deleteNoteCalledWith = id
        try deleteNoteResult.get()
    }
}
