import SwiftUI

struct SettingsView: View {
    @ObservedObject var appState: AppState
    @AppStorage("keyboard_enabled") private var keyboardEnabled = false
    
    @AppStorage("enable_haptics", store: UserDefaults(suiteName: "group.com.aryamirsepasi.writingtools"))
    private var enableHaptics = true
    
    @StateObject private var commandsManager = CustomCommandsManager()
    
    var body: some View {
        NavigationView {
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
                            
                            Text("1. Open Settings > General > Keyboard")
                                .font(.caption)
                            Text("2. Tap 'Keyboards' > 'Add New Keyboard'")
                                .font(.caption)
                            Text("3. Select 'Writing Tools'")
                                .font(.caption)
                            Text("4. Enable 'Allow Full Access'")
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
                        //Text("Local LLM").tag("local")
                    }
                    
                    if appState.currentProvider == "gemini" {
                        GeminiSettingsView(appState: appState)
                    } else if appState.currentProvider == "openai"{
                        OpenAISettingsView(appState: appState)
                    } else if appState.currentProvider == "mistral"{
                        MistralSettingsView(appState: appState)
                    } /*else{
                        LocalLLMSettingsView(evaluator: appState.localLLMProvider)
                    }*/
                }
                
                // Keyboard Preferences: only Haptics remains
                Section(header: Text("Keyboard Preferences")) {
                    Toggle("Enable Haptics", isOn: $enableHaptics)
                }
                
                Section(header: Text("Custom Commands")) {
                    NavigationLink("Manage Custom Commands") {
                        CustomCommandsView(commandsManager: commandsManager)
                    }
                }
                
                Section(header: Text("About")) {
                    Link("View on GitHub", destination: URL(string: "https://github.com/Aryamirsepasi/writing-tools-keyboard")!)
                    Text("Version 1.0.0")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Writing Tools")
        }
    }
    
    private func openKeyboardSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}