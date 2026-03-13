import SwiftUI

struct ContentView: View {
    @State private var searchText: String = ""
    @State private var notes: [Note] = [
        Note(title: "Покупки"),
        Note(title: "Рабочие задачи"),
        Note(title: "Идеи для проекта"),
        Note(title: "Книги для чтения"),
        Note(title: "Заметки с встречи")
    ]

    var filteredNotes: [Note] {
        if searchText.isEmpty { return notes }
        return notes.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredNotes) { note in
                    Text(note.title)
                }
            }
            .overlay {
                if filteredNotes.isEmpty && !searchText.isEmpty {
                    ContentUnavailableView.search
                }
            }
            .navigationTitle("Notes")
            .searchable(
                text: $searchText,
                prompt: String(localized: "notes_search_placeholder")
            )
        }
    }
}

#Preview {
    ContentView()
}
