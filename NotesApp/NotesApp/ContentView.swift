import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Notes App")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .accessibilityIdentifier("notes_app_title")
                Text("Welcome to the Notes App")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .accessibilityIdentifier("welcome_message")
            }
            .padding()
            .navigationTitle("Notes")
        }
    }
}

#Preview {
    ContentView()
}
