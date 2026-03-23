import Foundation
@testable import NotesApp

/// Mock implementation of APIServiceProtocol for unit testing.
final class MockAPIService: APIServiceProtocol {
    var fetchNotesResult: Result<[Note], Error> = .success([])
    var createNoteResult: Result<Note, Error> = .success(Note(title: "", content: ""))
    var deleteNoteResult: Result<Void, Error> = .success(())

    private(set) var fetchNotesCalled = false
    private(set) var createNoteCallArgs: [(title: String, content: String)] = []
    private(set) var deleteNoteCallArgs: [String] = []

    func fetchNotes() async throws -> [Note] {
        fetchNotesCalled = true
        return try fetchNotesResult.get()
    }

    func createNote(title: String, content: String) async throws -> Note {
        createNoteCallArgs.append((title: title, content: content))
        return try createNoteResult.get()
    }

    func deleteNote(id: String) async throws {
        deleteNoteCallArgs.append(id)
        try deleteNoteResult.get()
    }
}
