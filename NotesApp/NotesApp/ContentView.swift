import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Notes App")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("Welcome to the Notes App")
                    .font(.body)
                    .foregroundColor(.secondary)

                NavigationLink {
                    NoteEditView()
                } label: {
                    Label(NSLocalizedString("note_title_placeholder", comment: ""), systemImage: "square.and.pencil")
                }
                .accessibilityLabel(NSLocalizedString("note_title_placeholder", comment: ""))
            }
            .padding()
            .navigationTitle("Notes")
        }
    }
}

#Preview {
    ContentView()
}
