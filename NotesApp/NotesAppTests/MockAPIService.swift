import Foundation
@testable import NotesApp

/// Mock implementation of APIServiceProtocol for unit testing.
final class MockAPIService: APIServiceProtocol {
    var fetchNotesResult: Result<[Note], Error> = .success([])
    var createNoteResult: Result<Note, Error> = .success(
        Note(id: "new-1", title: "New", content: "", userId: nil,
             createdAt: Date(), updatedAt: Date(), categories: [])
    )
    var deleteNoteResult: Result<Void, Error> = .success(())
    var fetchDevTokenResult: Result<Void, Error> = .success(())

    private(set) var fetchNotesCalled = false
    private(set) var createNoteCallCount = 0
    private(set) var lastCreatedTitle: String?
    private(set) var lastCreatedContent: String?
    private(set) var deleteNoteCallCount = 0
    private(set) var lastDeletedId: String?
    private(set) var fetchDevTokenCalled = false

    func fetchNotes() async throws -> [Note] {
        fetchNotesCalled = true
        return try fetchNotesResult.get()
    }

    func createNote(title: String, content: String) async throws -> Note {
        createNoteCallCount += 1
        lastCreatedTitle = title
        lastCreatedContent = content
        return try createNoteResult.get()
    }

    func deleteNote(id: String) async throws {
        deleteNoteCallCount += 1
        lastDeletedId = id
        try deleteNoteResult.get()
    }

    func fetchDevToken() async throws {
        fetchDevTokenCalled = true
        try fetchDevTokenResult.get()
    }
}
