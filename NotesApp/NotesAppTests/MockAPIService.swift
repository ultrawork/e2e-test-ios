import Foundation
@testable import NotesApp

final class MockAPIService: APIServiceProtocol {
    var shouldThrowError: APIError?
    var stubbedNotes: [Note] = []
    var createdNote: Note?
    var deleteCalled = false
    var deleteCalledWithId: String?

    func fetchNotes() async throws -> [Note] {
        if let error = shouldThrowError { throw error }
        return stubbedNotes
    }

    func createNote(title: String, content: String) async throws -> Note {
        if let error = shouldThrowError { throw error }
        let note = createdNote ?? Note(id: UUID().uuidString, title: title, content: content)
        return note
    }

    func deleteNote(id: String) async throws {
        if let error = shouldThrowError { throw error }
        deleteCalled = true
        deleteCalledWithId = id
    }
}
