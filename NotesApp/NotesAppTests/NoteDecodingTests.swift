import XCTest
@testable import NotesApp

final class NoteDecodingTests: XCTestCase {

    private var decoder: JSONDecoder!

    override func setUp() {
        super.setUp()
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    override func tearDown() {
        decoder = nil
        super.tearDown()
    }

    // MARK: - Note Decoding

    func testDecodeNoteWithAllFields() throws {
        let json = """
        {
            "id": "abc-123",
            "title": "Test Note",
            "content": "Some content",
            "isFavorited": true,
            "categories": [
                {
                    "id": "cat-1",
                    "name": "Work",
                    "color": "#FF0000",
                    "createdAt": "2025-01-01T00:00:00Z"
                }
            ],
            "createdAt": "2025-01-01T00:00:00Z",
            "updatedAt": "2025-01-02T00:00:00Z"
        }
        """.data(using: .utf8)!

        let note = try decoder.decode(Note.self, from: json)

        XCTAssertEqual(note.id, "abc-123")
        XCTAssertEqual(note.title, "Test Note")
        XCTAssertEqual(note.content, "Some content")
        XCTAssertTrue(note.isFavorited)
        XCTAssertEqual(note.categories.count, 1)
        XCTAssertEqual(note.categories.first?.name, "Work")
    }

    func testDecodeNoteWithoutOptionalFields() throws {
        let json = """
        {
            "id": "abc-456",
            "title": "Minimal Note",
            "content": "",
            "createdAt": "2025-01-01T00:00:00Z",
            "updatedAt": "2025-01-01T00:00:00Z"
        }
        """.data(using: .utf8)!

        let note = try decoder.decode(Note.self, from: json)

        XCTAssertEqual(note.id, "abc-456")
        XCTAssertEqual(note.title, "Minimal Note")
        XCTAssertFalse(note.isFavorited, "isFavorited should default to false")
        XCTAssertTrue(note.categories.isEmpty, "categories should default to empty array")
    }

    func testDecodeNoteIsFavoritedDefaultsFalse() throws {
        let json = """
        {
            "id": "1",
            "title": "T",
            "content": "C",
            "isFavorited": null,
            "categories": [],
            "createdAt": "2025-01-01T00:00:00Z",
            "updatedAt": "2025-01-01T00:00:00Z"
        }
        """.data(using: .utf8)!

        let note = try decoder.decode(Note.self, from: json)
        XCTAssertFalse(note.isFavorited, "null isFavorited should default to false")
    }

    func testDecodeMultipleNotes() throws {
        let json = """
        [
            {
                "id": "1",
                "title": "First",
                "content": "A",
                "createdAt": "2025-01-01T00:00:00Z",
                "updatedAt": "2025-01-01T00:00:00Z"
            },
            {
                "id": "2",
                "title": "Second",
                "content": "B",
                "isFavorited": true,
                "createdAt": "2025-02-01T00:00:00Z",
                "updatedAt": "2025-02-01T00:00:00Z"
            }
        ]
        """.data(using: .utf8)!

        let notes = try decoder.decode([Note].self, from: json)
        XCTAssertEqual(notes.count, 2)
        XCTAssertEqual(notes[0].title, "First")
        XCTAssertFalse(notes[0].isFavorited)
        XCTAssertEqual(notes[1].title, "Second")
        XCTAssertTrue(notes[1].isFavorited)
    }

    func testDecodeNoteFailsWithMissingRequiredField() {
        let json = """
        {
            "id": "1",
            "content": "Missing title",
            "createdAt": "2025-01-01T00:00:00Z",
            "updatedAt": "2025-01-01T00:00:00Z"
        }
        """.data(using: .utf8)!

        XCTAssertThrowsError(try decoder.decode(Note.self, from: json))
    }

    // MARK: - Category Decoding

    func testDecodeCategoryAllFields() throws {
        let json = """
        {
            "id": "cat-1",
            "name": "Personal",
            "color": "#00FF00",
            "createdAt": "2025-03-15T10:30:00Z"
        }
        """.data(using: .utf8)!

        let category = try decoder.decode(Category.self, from: json)
        XCTAssertEqual(category.id, "cat-1")
        XCTAssertEqual(category.name, "Personal")
        XCTAssertEqual(category.color, "#00FF00")
    }

    // MARK: - APIError

    func testAPIErrorInvalidURLDescription() {
        let error = APIError.invalidURL
        XCTAssertEqual(error.errorDescription, "Invalid URL")
    }

    func testAPIErrorHTTPErrorDescription() {
        let error = APIError.httpError(404)
        XCTAssertEqual(error.errorDescription, "HTTP error 404")
    }

    func testAPIErrorHTTPError500Description() {
        let error = APIError.httpError(500)
        XCTAssertEqual(error.errorDescription, "HTTP error 500")
    }
}
