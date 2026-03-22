import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = NotesViewModel()
    @State private var newNoteText = ""
    @State private var searchText = ""

    private var trimmedSearch: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var filteredNotes: [Note] {
        var result = viewModel.notes
        if viewModel.showFavoritesOnly {
            result = result.filter { $0.isFavorited }
        }
        if !trimmedSearch.isEmpty {
            result = result.filter { $0.text.localizedCaseInsensitiveContains(trimmedSearch) }
        }
        return result
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                NotesCounterView(
                    totalCount: viewModel.notes.count,
                    filteredCount: trimmedSearch.isEmpty ? nil : filteredNotes.count
                )
                .padding(.vertical, 8)

                List {
                    ForEach(filteredNotes) { note in
                        HStack {
                            Text(note.text)
                            Spacer()
                            Button {
                                viewModel.toggleFavorite(id: note.id)
                            } label: {
                                Image(systemName: note.isFavorited ? "star.fill" : "star")
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("favorite_button_\(note.id)")
                            .accessibilityLabel(
                                note.isFavorited
                                    ? NSLocalizedString("notes_favorite_button_unmark", comment: "Remove from favorites")
                                    : NSLocalizedString("notes_favorite_button_mark", comment: "Add to favorites")
                            )
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                viewModel.notes.removeAll { $0.id == note.id }
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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.toggleShowFavoritesOnly()
                    } label: {
                        Image(systemName: viewModel.showFavoritesOnly ? "star.fill" : "star")
                    }
                    .accessibilityIdentifier("favorites_filter_button")
                    .accessibilityLabel(
                        NSLocalizedString("notes_favorites_filter_button", comment: "Filter favorites button")
                    )
                }
            }
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
