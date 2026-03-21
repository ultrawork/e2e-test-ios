import SwiftUI

/// Horizontal scroll view with an "All" button and category filter buttons.
struct CategoryFilterView: View {
    let categories: [Category]
    @Binding var selected: Category?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                allButton
                ForEach(categories) { category in
                    Button {
                        selected = category
                    } label: {
                        CategoryBadgeView(
                            category: category,
                            isSelected: selected?.id == category.id
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("category_filter_item_\(category.id)")
                }
            }
            .padding(.horizontal)
        }
    }

    private var allButton: some View {
        Button {
            selected = nil
        } label: {
            Text("Все")
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .foregroundStyle(selected == nil ? Color.primary : .secondary)
                .background(
                    Capsule().fill(Color(.systemGray5))
                )
                .overlay(
                    Capsule().stroke(Color.secondary, lineWidth: selected == nil ? 1.5 : 0)
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("category_filter_all_button")
    }
}

#Preview {
    struct FilterPreview: View {
        @State private var selected: Category?
        let categories = [
            Category(id: "1", name: "Work", color: "#FF9800"),
            Category(id: "2", name: "Personal", color: "#4CAF50"),
            Category(id: "3", name: "Ideas", color: "#2196F3"),
        ]

        var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                CategoryFilterView(categories: categories, selected: $selected)
                Text("Selected: \(selected?.name ?? "All")")
                    .padding(.horizontal)
            }
        }
    }
    return FilterPreview()
}
