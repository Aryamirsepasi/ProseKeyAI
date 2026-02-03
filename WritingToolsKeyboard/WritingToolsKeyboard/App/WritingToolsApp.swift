import SwiftUI

@main
struct WritingToolsApp: App {
    @StateObject private var commandsManager = KeyboardCommandsManager()
    
    var body: some Scene {
        WindowGroup {
            if #available(iOS 18.0, *) {
                TabView {
                    Tab("Home", systemImage: "house.fill") {
                        NavigationStack {
                            SettingsView()
                        }
                    }
                    
                    Tab("Commands", systemImage: "list.bullet.rectangle.fill") {
                        NavigationStack {
                            CommandsView(commandsManager: commandsManager)
                        }
                    }
                }
            } else {
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
}
