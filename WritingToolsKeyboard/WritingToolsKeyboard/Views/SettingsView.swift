import SwiftUI

struct SettingsView: View {
    @ObservedObject var appState: AppState
    @AppStorage("keyboard_enabled") private var keyboardEnabled = false
    
    @AppStorage("show_number_row", store: UserDefaults(suiteName: "group.com.aryamirsepasi.writingtools"))
    private var showNumberRow = true
    
    @AppStorage("enable_autocorrect", store: UserDefaults(suiteName: "group.com.aryamirsepasi.writingtools"))
    private var enableAutocorrect = true
    
    @AppStorage("enable_suggestions", store: UserDefaults(suiteName: "group.com.aryamirsepasi.writingtools"))
    private var enableSuggestions = true
    
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
                    }
                    
                    if appState.currentProvider == "gemini" {
                        GeminiSettingsView(appState: appState)
                    } else {
                        OpenAISettingsView(appState: appState)
                    }
                }
                
                Section(header: Text("Keyboard Preferences")) {
                    Toggle("Show Number Row", isOn: $showNumberRow)
                    Toggle("Enable Autocorrect", isOn: $enableAutocorrect)
                    Toggle("Enable Suggestions", isOn: $enableSuggestions)
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
