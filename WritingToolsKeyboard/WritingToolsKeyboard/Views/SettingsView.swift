import SwiftUI

struct SettingsView: View {
    @ObservedObject var appState: AppState
    @State private var keyboardEnabled: Bool = false
    
    @AppStorage("enable_haptics", store: UserDefaults(suiteName: "group.com.aryamirsepasi.writingtools"))
    
    private var enableHaptics = false

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var showOnboarding: Bool = false
    
    @StateObject private var commandsManager = KeyboardCommandsManager()
    
    private func checkKeyboardStatus() {
        // Check if our keyboard is in the list of enabled keyboards
        // This is an indirect way since there's no public API for this
        let extensionID = "com.aryamirsepasi.writingtools.WritingToolsKeyboardExt"
        
        // Check app container for evidence of keyboard usage
        let keyboardUsed = UserDefaults(suiteName: "group.com.aryamirsepasi.writingtools")?
            .bool(forKey: "keyboard_has_been_used") ?? false
            
        // Check if we've previously detected the keyboard
        let previouslyEnabled = UserDefaults.standard.bool(forKey: "keyboard_enabled")
        
        // Use all available evidence
        keyboardEnabled = keyboardUsed || previouslyEnabled
        
        // Save the status
        UserDefaults.standard.set(keyboardEnabled, forKey: "keyboard_enabled")
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
                    Picker("Provider", selection: Binding(
                        get: { appState.currentProvider },
                        set: { appState.setCurrentProvider($0) }
                    )) {
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
                
                Section(header: Text("Commands")) {
                    NavigationLink("Manage Keyboard Commands") {
                        CommandsView(commandsManager: commandsManager)
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
        .onAppear {
            checkKeyboardStatus()
            
            if !hasCompletedOnboarding {
                showOnboarding = true
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView()
        }
    }
    
    private func openKeyboardSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
