import SwiftUI

struct Note: Identifiable {
    let id = UUID()
    let text: String
}

final class NotesViewModel: ObservableObject {
    @Published var notes: [Note] = []
}

struct ContentView: View {
    @StateObject private var viewModel = NotesViewModel()
    @State private var newNoteText = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                NotesCounterView(totalCount: viewModel.notes.count)
                    .padding(.vertical, 8)

                List {
                    ForEach(viewModel.notes) { note in
                        Text(note.text)
                    }
                    .onDelete { indexSet in
                        viewModel.notes.remove(atOffsets: indexSet)
                    }
                }
                .listStyle(.plain)

                HStack {
                    TextField("New note", text: $newNoteText)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityLabel(
                            NSLocalizedString("notes_new_note_field", comment: "New note text field")
                        )

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
                }
                .padding()
            }
            .navigationTitle("Notes")
        }
    }
}

#Preview {
    ContentView()
}
