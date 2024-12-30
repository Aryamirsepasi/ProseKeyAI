import SwiftUI

@main
struct WritingToolsApp: App {
    @StateObject private var appState = AppState.shared
    
    var body: some Scene {
        WindowGroup {
            SettingsView(appState: appState)
        }
    }
}
