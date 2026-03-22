import SwiftUI

@main
struct NotesApp: App {
    private let apiService: APIServiceProtocol

    init() {
        if ProcessInfo.processInfo.arguments.contains("--uitesting") {
            apiService = MockAPIService()
        } else {
            apiService = APIService.shared
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(apiService: apiService)
        }
    }
}
