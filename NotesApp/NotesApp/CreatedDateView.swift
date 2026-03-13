import SwiftUI

struct CreatedDateView: View {
    let createdAt: Date?

    @State private var fallbackDate = Date()

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        return formatter
    }()

    private var displayDate: Date {
        createdAt ?? fallbackDate
    }

    private var formattedDate: String {
        Self.dateFormatter.string(from: displayDate)
    }

    var body: some View {
        Text(formattedDate)
            .font(.caption)
            .foregroundColor(.gray)
            .accessibilityIdentifier("created_date_text")
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
