import XCTest
@testable import NotesApp

final class NoteModelTests: XCTestCase {

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    func testNote_decodesFromJSON() throws {
        let json = """
        {
            "id": "abc-123",
            "title": "Test Note",
            "content": "Some content",
            "createdAt": "2025-01-15T10:30:00Z",
            "updatedAt": "2025-01-15T11:00:00Z",
            "categories": []
        }
        """.data(using: .utf8)!

        let note = try decoder.decode(Note.self, from: json)

        XCTAssertEqual(note.id, "abc-123")
        XCTAssertEqual(note.title, "Test Note")
        XCTAssertEqual(note.content, "Some content")
        XCTAssertEqual(note.categories.count, 0)
        XCTAssertFalse(note.isFavorited)
    }

    func testNote_decodesWithCategories() throws {
        let json = """
        {
            "id": "note-1",
            "title": "Categorized",
            "content": "",
            "createdAt": "2025-01-15T10:30:00Z",
            "updatedAt": "2025-01-15T11:00:00Z",
            "categories": [
                {
                    "id": "cat-1",
                    "name": "Work",
                    "color": "#FF0000",
                    "createdAt": "2025-01-10T08:00:00Z"
                }
            ]
        }
        """.data(using: .utf8)!

        let note = try decoder.decode(Note.self, from: json)

        XCTAssertEqual(note.categories.count, 1)
        XCTAssertEqual(note.categories[0].name, "Work")
        XCTAssertEqual(note.categories[0].color, "#FF0000")
    }

    func testNote_isFavoritedNotEncoded() throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        var note = Note(
            id: "enc-1",
            title: "Encode Test",
            content: "",
            createdAt: Date(),
            updatedAt: Date(),
            categories: []
        )
        note.isFavorited = true

        let data = try encoder.encode(note)
        let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertNotNil(dict)
        XCTAssertNil(dict?["isFavorited"], "isFavorited should not be serialized")
        XCTAssertNotNil(dict?["title"])
    }
}
