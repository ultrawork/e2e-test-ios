import SwiftUI

/// Capsule-shaped colored badge displaying a category name.
struct CategoryBadgeView: View {
    let category: Category
    var isSelected: Bool = false

    var body: some View {
        Text(category.name)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundStyle(textColor)
            .background(
                Capsule().fill(category.swiftUIColor)
            )
            .overlay(
                Capsule().stroke(Color.secondary, lineWidth: isSelected ? 1.5 : 0)
            )
            .clipShape(Capsule())
            .accessibilityLabel("Категория: \(category.name)")
    }

    /// Determines text color (black or white) based on YIQ brightness of the category hex color.
    private var textColor: Color {
        let brightness = Self.yiqBrightness(hex: category.color)
        return brightness >= 128 ? .black : .white
    }

    /// Computes YIQ brightness from a hex color string (#RRGGBB or #RGB).
    static func yiqBrightness(hex: String) -> Double {
        var hexString = hex
        if hexString.hasPrefix("#") {
            hexString.removeFirst()
        }

        // Normalize #RGB to #RRGGBB
        if hexString.count == 3 {
            hexString = hexString.map { "\($0)\($0)" }.joined()
        }

        guard hexString.count == 6,
              let value = UInt64(hexString, radix: 16) else {
            return 128
        }

        let r = Double((value >> 16) & 0xFF)
        let g = Double((value >> 8) & 0xFF)
        let b = Double(value & 0xFF)

        return (r * 299 + g * 587 + b * 114) / 1000
    }
}

#Preview("Multiple Badges") {
    let categories = [
        Category(id: "1", name: "Work", color: "#FF9800"),
        Category(id: "2", name: "Personal", color: "#4CAF50"),
        Category(id: "3", name: "Ideas", color: "#2196F3"),
        Category(id: "4", name: "Dark", color: "#1A1A2E"),
    ]
    VStack(spacing: 12) {
        ForEach(categories) { category in
            HStack {
                CategoryBadgeView(category: category)
                CategoryBadgeView(category: category, isSelected: true)
            }
        }
    }
    .padding()
}

#Preview("Dark Mode") {
    let categories = [
        Category(id: "1", name: "Work", color: "#FF9800"),
        Category(id: "2", name: "Personal", color: "#4CAF50"),
    ]
    VStack(spacing: 12) {
        ForEach(categories) { category in
            CategoryBadgeView(category: category)
        }
    }
    .padding()
    .preferredColorScheme(.dark)
}
