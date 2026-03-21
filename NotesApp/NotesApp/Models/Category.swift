import Foundation
import SwiftUI

/// Model representing a note category synced with backend.
struct Category: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var color: String
    var createdAt: String?

    /// Returns the SwiftUI `Color` parsed from `color` hex string, or `.gray` as fallback.
    var swiftUIColor: Color {
        Color(hex: color) ?? .gray
    }

    /// Validates that the trimmed name is between 1 and 30 characters.
    static func validateName(_ name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return (1...30).contains(trimmed.count)
    }

    /// Validates that the color matches the pattern `#[0-9A-Fa-f]{6}`.
    static func validateColor(_ color: String) -> Bool {
        let pattern = "^#[0-9A-Fa-f]{6}$"
        return color.range(of: pattern, options: .regularExpression) != nil
    }
}

extension Color {
    /// Initializes a `Color` from a hex string in `#RRGGBB` or `RRGGBB` format.
    init?(hex: String) {
        var hexString = hex
        if hexString.hasPrefix("#") {
            hexString.removeFirst()
        }

        guard hexString.count == 6 else { return nil }
        guard let value = UInt64(hexString, radix: 16) else { return nil }

        let r = Double((value >> 16) & 0xFF) / 255.0
        let g = Double((value >> 8) & 0xFF) / 255.0
        let b = Double(value & 0xFF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}
