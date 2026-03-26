import SwiftUI

@main
struct NotesApp: App {

    init() {
        if CommandLine.arguments.contains("-resetDefaults") {
            UserDefaults.standard.removeObject(forKey: "jwtToken")
        }
        if let token = ProcessInfo.processInfo.environment["JWT_TOKEN"] {
            UserDefaults.standard.set(token, forKey: "jwtToken")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
