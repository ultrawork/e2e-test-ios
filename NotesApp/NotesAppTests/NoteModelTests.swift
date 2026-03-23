import XCTest
@testable import NotesApp

final class NoteModelTests: XCTestCase {

    // MARK: - Note Decoding

    func testNoteDecoding() throws {
        let json = """
        {
            "id": "abc-123",
            "title": "Test Title",
            "content": "Test Content",
            "userId": "user-1",
            "createdAt": "2025-01-15T10:30:00Z",
            "updatedAt": "2025-01-15T11:00:00Z",
            "categories": []
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let note = try decoder.decode(Note.self, from: json)

        XCTAssertEqual(note.id, "abc-123")
        XCTAssertEqual(note.title, "Test Title")
        XCTAssertEqual(note.content, "Test Content")
        XCTAssertEqual(note.userId, "user-1")
        XCTAssertFalse(note.isFavorited)
    }

    func testNoteDecodingWithCategories() throws {
        let json = """
        {
            "id": "abc-456",
            "title": "With Categories",
            "content": "Content",
            "userId": "user-2",
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

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let note = try decoder.decode(Note.self, from: json)

        XCTAssertEqual(note.categories.count, 1)
        XCTAssertEqual(note.categories[0].name, "Work")
        XCTAssertEqual(note.categories[0].color, "#FF0000")
    }

    // MARK: - Note Encoding (isFavorited excluded)

    func testNoteEncodingExcludesIsFavorited() throws {
        let note = Note(
            id: "enc-1",
            title: "Encode Test",
            content: "Content",
            userId: "user-1",
            createdAt: Date(),
            updatedAt: Date(),
            categories: []
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(note)
        let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertNotNil(dict)
        XCTAssertNil(dict?["isFavorited"])
        XCTAssertNotNil(dict?["title"])
    }

    // MARK: - Category Decoding

    func testCategoryDecoding() throws {
        let json = """
        {
            "id": "cat-1",
            "name": "Personal",
            "color": "#00FF00",
            "createdAt": "2025-01-10T08:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let category = try decoder.decode(Category.self, from: json)

        XCTAssertEqual(category.id, "cat-1")
        XCTAssertEqual(category.name, "Personal")
        XCTAssertEqual(category.color, "#00FF00")
    }
}
