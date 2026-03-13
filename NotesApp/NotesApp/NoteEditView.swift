import SwiftUI

struct NoteEditView: View {
    let note: NoteItem?

    @State private var title: String = ""
    @State private var content: String = ""

    init(note: NoteItem? = nil) {
        self.note = note
        _title = State(initialValue: note?.title ?? "")
        _content = State(initialValue: note?.content ?? "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TextField(
                NSLocalizedString("note_title_placeholder", comment: ""),
                text: $title
            )
            .font(.title2)
            .fontWeight(.bold)
            .textFieldStyle(.plain)
            .accessibilityIdentifier("note_title_field")
            .accessibilityLabel(NSLocalizedString("note_title_accessibility", comment: ""))

            CreatedDateView(createdAt: note?.createdAt)
                .padding(.top, 4)

            TextEditor(text: $content)
                .font(.body)
                .padding(.top, 12)
                .accessibilityIdentifier("note_content_field")
                .accessibilityLabel(NSLocalizedString("note_content_accessibility", comment: ""))
        }
        .padding()
        .navigationTitle(
            note == nil
                ? NSLocalizedString("new_note_title", comment: "")
                : NSLocalizedString("edit_note_title", comment: "")
        )
    }
}

struct NoteItem: Identifiable {
    let id: String
    let title: String
    let content: String
    let createdAt: Date?
}

#Preview {
    NavigationStack {
        NoteEditView(note: NoteItem(
            id: "1",
            title: "Sample Note",
            content: "Some content here",
            createdAt: Date()
        ))
    }
}
