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
            }
            .padding()
            .navigationTitle("Notes")
        }
    }
}

#Preview {
    ContentView()
}
