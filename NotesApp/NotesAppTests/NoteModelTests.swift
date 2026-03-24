import XCTest
@testable import NotesApp

final class NoteModelTests: XCTestCase {

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    func testNoteDecodingFromJSON() throws {
        let json = """
        {
            "id": "abc-123",
            "title": "Test Note",
            "content": "Some content",
            "userId": "user-1",
            "createdAt": "2024-01-15T10:30:00Z",
            "updatedAt": "2024-01-15T11:00:00Z",
            "categories": [
                {
                    "id": "cat-1",
                    "name": "Work",
                    "color": "#FF0000",
                    "createdAt": "2024-01-01T00:00:00Z"
                }
            ]
        }
        """.data(using: .utf8)!

        let note = try decoder.decode(Note.self, from: json)

        XCTAssertEqual(note.id, "abc-123")
        XCTAssertEqual(note.title, "Test Note")
        XCTAssertEqual(note.content, "Some content")
        XCTAssertEqual(note.userId, "user-1")
        XCTAssertEqual(note.categories.count, 1)
        XCTAssertEqual(note.categories.first?.name, "Work")
        XCTAssertFalse(note.isFavorited)
    }

    func testNoteDecodingWithNullUserId() throws {
        let json = """
        {
            "id": "abc-456",
            "title": "No User",
            "content": "Content",
            "userId": null,
            "createdAt": "2024-01-15T10:30:00Z",
            "updatedAt": "2024-01-15T11:00:00Z",
            "categories": []
        }
        """.data(using: .utf8)!

        let note = try decoder.decode(Note.self, from: json)

        XCTAssertNil(note.userId)
        XCTAssertTrue(note.categories.isEmpty)
    }

    func testIsFavoritedNotInJSON() throws {
        let json = """
        {
            "id": "1",
            "title": "T",
            "content": "C",
            "userId": null,
            "createdAt": "2024-01-15T10:30:00Z",
            "updatedAt": "2024-01-15T10:30:00Z",
            "categories": []
        }
        """.data(using: .utf8)!

        let note = try decoder.decode(Note.self, from: json)
        XCTAssertFalse(note.isFavorited, "isFavorited should default to false")
    }

    func testNoteEquatable() {
        let date = Date()
        let note1 = Note(id: "1", title: "A", content: "B", userId: nil,
                         createdAt: date, updatedAt: date, categories: [])
        let note2 = Note(id: "1", title: "A", content: "B", userId: nil,
                         createdAt: date, updatedAt: date, categories: [])
        XCTAssertEqual(note1, note2)
    }
}
