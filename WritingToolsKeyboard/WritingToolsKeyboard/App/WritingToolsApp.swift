import SwiftUI

@main
struct WritingToolsApp: App {
    @StateObject private var commandsManager = KeyboardCommandsManager()
    
    var body: some Scene {
        WindowGroup {
            TabView {
                NavigationStack {
                    SettingsView()
                }
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                
                NavigationStack {
                    CommandsView(commandsManager: commandsManager)
                }
                .tabItem {
                    Label("Commands", systemImage: "list.bullet.rectangle.fill")
                }
            }
        }
    }
}
