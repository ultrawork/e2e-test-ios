import SwiftUI

struct CreatedDateView: View {
    let createdAt: Date?

    private var displayDate: Date {
        createdAt ?? Date()
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        return formatter.string(from: displayDate)
    }

    var body: some View {
        Text(formattedDate)
            .font(.caption)
            .foregroundColor(.gray)
            .accessibilityLabel(
                String(
                    format: NSLocalizedString("created_date_accessibility", comment: ""),
                    formattedDate
                )
            )
    }
}

#Preview {
    VStack {
        CreatedDateView(createdAt: Date())
        CreatedDateView(createdAt: nil)
    }
}
