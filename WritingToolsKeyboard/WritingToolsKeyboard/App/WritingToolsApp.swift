import SwiftUI

@main
struct WritingToolsApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
              SettingsView(appState: AppState.shared)
            }
        }
    }
}
