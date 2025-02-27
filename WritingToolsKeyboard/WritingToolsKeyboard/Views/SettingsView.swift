import SwiftUI

struct SettingsView: View {
    @ObservedObject var appState: AppState
    @AppStorage("keyboard_enabled") private var keyboardEnabled = false
    
    @AppStorage("enable_haptics", store: UserDefaults(suiteName: "group.com.aryamirsepasi.writingtools"))
    private var enableHaptics = true
    
    @StateObject private var commandsManager = CustomCommandsManager()
    
    init(appState: AppState) {
        self.appState = appState
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: UIFont.boldSystemFont(ofSize: 34)
        ]
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().prefersLargeTitles = true
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Keyboard Status")) {
                    HStack {
                        Text("Writing Tools Keyboard")
                        Spacer()
                        if keyboardEnabled {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else {
                            Button("Enable") {
                                openKeyboardSettings()
                            }
                        }
                    }
                    
                    if !keyboardEnabled {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("To enable the keyboard:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("1. Press the above button")
                                .font(.caption)
                            Text("2. Tap 'Keyboards' > Enable 'Writing Tools'")
                                .font(.caption)
                            Text("3. Enable 'Allow Full Access'")
                                .font(.caption)
                            Text("4. For more convenience, also allow pasting from other apps.")
                                .font(.caption)
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section(header: Text("AI Provider")) {
                    Picker("Provider", selection: $appState.currentProvider) {
                        Text("Gemini AI").tag("gemini")
                        Text("OpenAI").tag("openai")
                        Text("Mistral").tag("mistral")
                    }
                    
                    if appState.currentProvider == "gemini" {
                        GeminiSettingsView(appState: appState)
                    } else if appState.currentProvider == "openai" {
                        OpenAISettingsView(appState: appState)
                    } else if appState.currentProvider == "mistral" {
                        MistralSettingsView(appState: appState)
                    }
                }
                
                Section(header: Text("Keyboard Preferences")) {
                    Toggle("Enable Haptics", isOn: $enableHaptics)
                }
                
                Section(header: Text("Custom Commands")) {
                    NavigationLink("Manage Custom Commands") {
                        CustomCommandsView(commandsManager: commandsManager)
                    }
                }
                
                Section(header: Text("About")) {
                    Link("View on GitHub", destination: URL(string: "https://github.com/Aryamirsepasi/WritingToolsKeyboard")!)
                    Text("Version 1.0.1")
                        .foregroundColor(.secondary)
                    Text("Developed by Arya Mirsepasi")
                        .foregroundColor(.secondary)
                    Link("Website", destination: URL(string: "https://aryamirsepasi.com")!)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Writing Tools")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private func openKeyboardSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
