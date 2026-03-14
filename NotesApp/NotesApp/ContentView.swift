import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = NotesViewModel()
    @State private var newNoteText = ""
    @State private var searchText = ""

    var filteredNotes: [Note] {
        if searchText.isEmpty {
            return viewModel.notes
        }
        return viewModel.notes.filter { $0.text.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                NotesCounterView(
                    totalCount: viewModel.notes.count,
                    filteredCount: searchText.isEmpty ? nil : filteredNotes.count
                )
                .padding(.vertical, 8)

                List {
                    ForEach(filteredNotes) { note in
                        Text(note.text)
                    }
                    .onDelete { indexSet in
                        let idsToDelete = indexSet.map { filteredNotes[$0].id }
                        viewModel.notes.removeAll { idsToDelete.contains($0.id) }
                    }
                }
                .listStyle(.plain)
                .accessibilityIdentifier("notes_list")

                HStack {
                    TextField(NSLocalizedString("notes_new_note_placeholder", comment: "New note placeholder"), text: $newNoteText)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityLabel(
                            NSLocalizedString("notes_new_note_field", comment: "New note text field")
                        )
                        .accessibilityIdentifier("new_note_text_field")

                    Button {
                        guard !newNoteText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        viewModel.notes.append(Note(text: newNoteText))
                        newNoteText = ""
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                    .accessibilityLabel(
                        NSLocalizedString("notes_add_button", comment: "Add note button")
                    )
                    .accessibilityIdentifier("add_note_button")
                }
                .padding()
            }
            .navigationTitle(NSLocalizedString("notes_navigation_title", comment: "Notes screen title"))
            .searchable(
                text: $searchText,
                prompt: NSLocalizedString("search_notes_placeholder", comment: "Search notes placeholder")
            )
        }
    }
}

#Preview {
    ContentView()
}
