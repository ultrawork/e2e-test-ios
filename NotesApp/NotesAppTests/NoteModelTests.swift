import XCTest
@testable import NotesApp

final class NoteModelTests: XCTestCase {

    private var decoder: JSONDecoder!
    private var encoder: JSONEncoder!

    override func setUp() {
        super.setUp()
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
    }

    func testNote_decodesFromJSON() throws {
        let json = """
        {
            "id": "abc123",
            "title": "Test Note",
            "content": "Some content",
            "userId": "user1",
            "createdAt": "2025-01-01T00:00:00Z",
            "updatedAt": "2025-01-02T00:00:00Z",
            "categories": [
                {"id": "cat1", "name": "Work", "color": "#FF0000", "createdAt": "2025-01-01T00:00:00Z"}
            ]
        }
        """.data(using: .utf8)!

        let note = try decoder.decode(Note.self, from: json)

        XCTAssertEqual(note.id, "abc123")
        XCTAssertEqual(note.title, "Test Note")
        XCTAssertEqual(note.content, "Some content")
        XCTAssertEqual(note.userId, "user1")
        XCTAssertEqual(note.categories.count, 1)
        XCTAssertEqual(note.categories.first?.name, "Work")
        XCTAssertFalse(note.isFavorited)
    }

    func testNote_isFavoritedExcludedFromCoding() throws {
        let json = """
        {
            "id": "1",
            "title": "T",
            "content": "C",
            "userId": null,
            "createdAt": "2025-01-01T00:00:00Z",
            "updatedAt": "2025-01-01T00:00:00Z",
            "categories": []
        }
        """.data(using: .utf8)!

        var note = try decoder.decode(Note.self, from: json)
        note.isFavorited = true

        let encoded = try encoder.encode(note)
        let jsonString = String(data: encoded, encoding: .utf8) ?? ""

        XCTAssertFalse(jsonString.contains("isFavorited"))
    }

    func testNote_decodesWithNullUserId() throws {
        let json = """
        {
            "id": "1",
            "title": "T",
            "content": "C",
            "userId": null,
            "createdAt": "2025-01-01T00:00:00Z",
            "updatedAt": "2025-01-01T00:00:00Z",
            "categories": []
        }
        """.data(using: .utf8)!

        let note = try decoder.decode(Note.self, from: json)
        XCTAssertNil(note.userId)
    }
}
