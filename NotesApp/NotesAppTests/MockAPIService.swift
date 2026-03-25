import Foundation
@testable import NotesApp

final class MockAPIService: APIServiceProtocol {
    var fetchNotesResult: Result<[Note], Error> = .success([])
    var createNoteResult: Result<Note, Error> = .success(
        Note(
            id: "mock-id",
            title: "Mock",
            content: "",
            createdAt: Date(),
            updatedAt: Date(),
            categories: []
        )
    )
    var deleteNoteResult: Result<Void, Error> = .success(())
    var fetchDevTokenResult: Result<String, Error> = .success("mock-token")

    var fetchNotesCalled = false
    var createNoteCalled = false
    var deleteNoteCalled = false
    var fetchDevTokenCalled = false
    var lastDeletedId: String?
    var lastCreatedTitle: String?

    func fetchNotes() async throws -> [Note] {
        fetchNotesCalled = true
        return try fetchNotesResult.get()
    }

    func createNote(title: String, content: String) async throws -> Note {
        createNoteCalled = true
        lastCreatedTitle = title
        return try createNoteResult.get()
    }

    func deleteNote(id: String) async throws {
        deleteNoteCalled = true
        lastDeletedId = id
        try deleteNoteResult.get()
    }

    func fetchDevToken() async throws -> String {
        fetchDevTokenCalled = true
        return try fetchDevTokenResult.get()
    }
}
