import SwiftUI
import SwiftData

@main
struct WritingToolsApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                MainChatView()
                    .modelContainer(for: [Thread.self, Message.self])
                    .tabItem {
                        Label("Chat", systemImage: "bubble.left.and.bubble.right")
                    }
                
                NavigationView {
                    SettingsView(appState: AppState.shared)
                }
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
            }
        }
    }
}
