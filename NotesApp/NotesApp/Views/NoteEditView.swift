import SwiftUI

struct NoteEditView: View {
    @State private var title: String
    @State private var content: String

    init(title: String = "", content: String = "") {
        _title = State(initialValue: title)
        _content = State(initialValue: content)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField(
                NSLocalizedString("note_title_placeholder", comment: ""),
                text: $title
            )
            .font(.title2)
            .accessibilityLabel(NSLocalizedString("note_title_placeholder", comment: ""))

            TextEditor(text: $content)
                .frame(minHeight: 200)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .accessibilityLabel(NSLocalizedString("note_content_placeholder", comment: ""))

            CharacterCounter(count: content.count)

            Spacer()
        }
        .padding()
        .navigationTitle(title.isEmpty
            ? NSLocalizedString("note_title_placeholder", comment: "")
            : title)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(NSLocalizedString("save", comment: "")) {}
                    .accessibilityLabel(NSLocalizedString("save", comment: ""))
            }
        }
    }
}

#Preview {
    NavigationStack {
        NoteEditView()
    }
}
