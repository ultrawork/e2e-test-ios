import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = NotesViewModel()
    @State private var newNoteText = ""
    @State private var searchText = ""
    @State private var showErrorAlert = false

    private var trimmedSearch: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var filteredNotes: [Note] {
        if trimmedSearch.isEmpty {
            return viewModel.notes
        }
        return viewModel.notes.filter { $0.title.localizedCaseInsensitiveContains(trimmedSearch) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                NotesCounterView(
                    totalCount: viewModel.notes.count,
                    filteredCount: trimmedSearch.isEmpty ? nil : filteredNotes.count
                )
                .padding(.vertical, 8)

                ZStack {
                    List {
                        ForEach(filteredNotes) { note in
                            Text(note.title)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        Task {
                                            await viewModel.deleteNote(id: note.id)
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .listStyle(.plain)
                    .scrollDismissesKeyboard(.interactively)
                    .accessibilityIdentifier("notes_list")

                    if viewModel.isLoading {
                        ProgressView()
                    }
                }

                HStack {
                    TextField(NSLocalizedString("notes_new_note_placeholder", comment: "New note placeholder"), text: $newNoteText)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityLabel(
                            NSLocalizedString("notes_new_note_field", comment: "New note text field")
                        )
                        .accessibilityIdentifier("new_note_text_field")

                    Button {
                        guard !newNoteText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        let title = newNoteText
                        newNoteText = ""
                        Task {
                            await viewModel.addNote(title: title)
                        }
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
            .onAppear {
                Task {
                    await viewModel.loadNotes()
                }
            }
            .alert("Ошибка", isPresented: $showErrorAlert, actions: {
                Button("OK") {
                    viewModel.error = nil
                }
            }, message: {
                Text(viewModel.error?.localizedDescription ?? "Неизвестная ошибка")
            })
            .onChange(of: viewModel.error != nil) { _, hasError in
                showErrorAlert = hasError
            }
        }
    }
}

#Preview {
    ContentView()
}
