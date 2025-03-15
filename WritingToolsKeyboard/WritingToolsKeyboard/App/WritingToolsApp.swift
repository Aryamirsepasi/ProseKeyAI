import SwiftUI

@main
struct WritingToolsApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationView {
                SettingsView(appState: AppState.shared)
            }
        }
    }
}
