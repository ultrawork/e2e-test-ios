import SwiftUI

struct NotesCounterView: View {
    let totalCount: Int
    var filteredCount: Int?

    var body: some View {
        Text(counterText)
            .font(.subheadline)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .accessibilityLabel(counterText)
    }

    private var counterText: String {
        if let filtered = filteredCount {
            return String(
                format: NSLocalizedString("notes_counter_filtered", comment: "Filtered notes count"),
                filtered,
                totalCount
            )
        }
        return String(
            format: NSLocalizedString("notes_counter_total", comment: "Total notes count"),
            totalCount
        )
    }
}

#Preview {
    NotesCounterView(totalCount: 5)
}
