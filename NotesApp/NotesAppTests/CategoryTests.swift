import XCTest
import SwiftUI
@testable import NotesApp

final class CategoryTests: XCTestCase {

    // MARK: - Color parsing (valid)

    func testColorHexBlack() {
        let color = Color(hex: "#000000")
        XCTAssertNotNil(color)
        assertRGB(color!, r: 0, g: 0, b: 0)
    }

    func testColorHexRed() {
        let color = Color(hex: "#FF0000")
        XCTAssertNotNil(color)
        assertRGB(color!, r: 1, g: 0, b: 0)
    }

    func testColorHexGreenWithoutHash() {
        let color = Color(hex: "00FF00")
        XCTAssertNotNil(color)
        assertRGB(color!, r: 0, g: 1, b: 0)
    }

    func testColorHexBlue() {
        let color = Color(hex: "#0000FF")
        XCTAssertNotNil(color)
        assertRGB(color!, r: 0, g: 0, b: 1)
    }

    func testColorHexMixedCase() {
        let color = Color(hex: "#AaBbCc")
        XCTAssertNotNil(color)
        assertRGB(color!, r: Double(0xAA) / 255.0, g: Double(0xBB) / 255.0, b: Double(0xCC) / 255.0)
    }

    // MARK: - Color parsing (invalid)

    func testColorHexEmpty() {
        XCTAssertNil(Color(hex: ""))
    }

    func testColorHexTooShort() {
        XCTAssertNil(Color(hex: "#FFF"))
    }

    func testColorHexTooLong() {
        XCTAssertNil(Color(hex: "#1234567"))
    }

    func testColorHexInvalidChars() {
        XCTAssertNil(Color(hex: "GHIJKL"))
    }

    func testColorHexPartialInvalid() {
        XCTAssertNil(Color(hex: "#12G45Z"))
    }

    func testColorHexFiveDigits() {
        XCTAssertNil(Color(hex: "12345"))
    }

    func testColorHexDoubleHash() {
        XCTAssertNil(Color(hex: "##123456"))
    }

    // MARK: - Name validation

    func testValidateNameEmpty() {
        XCTAssertFalse(Category.validateName(""))
    }

    func testValidateNameWhitespace() {
        XCTAssertFalse(Category.validateName("   "))
    }

    func testValidateNameSingleChar() {
        XCTAssertTrue(Category.validateName("a"))
    }

    func testValidateNameMaxLength() {
        let name = String(repeating: "a", count: 30)
        XCTAssertTrue(Category.validateName(name))
    }

    func testValidateNameTooLong() {
        let name = String(repeating: "a", count: 31)
        XCTAssertFalse(Category.validateName(name))
    }

    // MARK: - Color validation

    func testValidateColorValid() {
        XCTAssertTrue(Category.validateColor("#1A2B3C"))
    }

    func testValidateColorLowercase() {
        XCTAssertTrue(Category.validateColor("#1a2b3c"))
    }

    func testValidateColorNoHash() {
        XCTAssertFalse(Category.validateColor("1A2B3C"))
    }

    func testValidateColorValidHex() {
        XCTAssertTrue(Category.validateColor("#ABCDEF"))
    }

    func testValidateColorInvalidHexChar() {
        XCTAssertFalse(Category.validateColor("#ABCDEG"))
    }

    // MARK: - Round-trip serialization

    func testCategoryRoundTripSerialization() throws {
        let original = Category(
            id: "cat-1",
            name: "Work",
            color: "#00FF00",
            createdAt: "2024-10-28T13:37:00Z"
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Category.self, from: data)

        XCTAssertEqual(original, decoded)
    }

    func testCategorySerializationKeys() throws {
        let category = Category(
            id: "cat-2",
            name: "Personal",
            color: "#FF0000",
            createdAt: nil
        )

        let data = try JSONEncoder().encode(category)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertNotNil(json["id"])
        XCTAssertNotNil(json["name"])
        XCTAssertNotNil(json["color"])
        XCTAssertTrue(json["createdAt"] is NSNull || json["createdAt"] == nil)
    }

    // MARK: - Helpers

    private func assertRGB(_ color: Color, r: Double, g: Double, b: Double, accuracy: Double = 1.0 / 255.0, file: StaticString = #file, line: UInt = #line) {
        #if canImport(UIKit)
        let uiColor = UIColor(color)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        XCTAssertEqual(Double(red), r, accuracy: accuracy, file: file, line: line)
        XCTAssertEqual(Double(green), g, accuracy: accuracy, file: file, line: line)
        XCTAssertEqual(Double(blue), b, accuracy: accuracy, file: file, line: line)
        #endif
    }
}
