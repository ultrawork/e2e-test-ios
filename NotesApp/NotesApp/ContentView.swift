import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = NotesViewModel(apiService: APIService())
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
        return viewModel.notes.filter {
            $0.title.localizedCaseInsensitiveContains(trimmedSearch)
            || $0.content.localizedCaseInsensitiveContains(trimmedSearch)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                NotesCounterView(
                    totalCount: viewModel.notes.count,
                    filteredCount: trimmedSearch.isEmpty ? nil : filteredNotes.count
                )
                .padding(.vertical, 8)

                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                        .accessibilityIdentifier("loading_indicator")
                }

                List {
                    ForEach(filteredNotes) { note in
                        Text(note.title)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    Task {
                                        await viewModel.deleteNote(note)
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
            .task {
                await viewModel.load()
            }
            .onChange(of: viewModel.errorMessage) { _, newValue in
                showErrorAlert = newValue != nil
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
}

#Preview {
    ContentView()
}
