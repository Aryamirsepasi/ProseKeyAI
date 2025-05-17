import SwiftUI

struct SettingsView: View {
    @StateObject var appState = AppState.shared
    @ObservedObject var settings = AppSettings.shared
    @State private var keyboardEnabled: Bool = false
    @State private var selectedTab = 0
    
    @AppStorage("enable_haptics", store: UserDefaults(suiteName: "group.com.aryamirsepasi.writingtools"))
    private var enableHaptics = false
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var showOnboarding: Bool = false
    @State private var showApiKeyHelp: Bool = false
    
    @StateObject private var commandsManager = KeyboardCommandsManager()
    
    // Custom colors
    private let accentGradient = LinearGradient(
        colors: [Color.blue, Color.purple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    private func checkKeyboardStatus() {
        let keyboardUsed = UserDefaults(suiteName: "group.com.aryamirsepasi.writingtools")?
            .bool(forKey: "keyboard_has_been_used") ?? false
        let previouslyEnabled = UserDefaults.standard.bool(forKey: "keyboard_enabled")
        keyboardEnabled = keyboardUsed || previouslyEnabled
        UserDefaults.standard.set(keyboardEnabled, forKey: "keyboard_enabled")
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Custom header
                    VStack(spacing: 4) {
                        Image(systemName: "keyboard.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(accentGradient)
                            .padding(.bottom, 10)
                        
                        Text("Enhance your writing with AI")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    // Keyboard status card
                    KeyboardStatusCard(
                        isEnabled: keyboardEnabled,
                        onEnablePressed: openKeyboardSettings
                    )
                    .padding(.horizontal)
                    
                    // Provider selection with visual tabs
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Select AI Provider")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ProviderTabView(
                            currentProvider: $settings.currentProvider // Bind to AppSettings
                        )
                        // Ensure AppState is updated when settings.currentProvider changes
                        .onChange(of: settings.currentProvider) { newProvider in
                            appState.setCurrentProvider(newProvider)
                        }
                        
                        ProviderSetupCard(
                            provider: settings.currentProvider, // Use settings.currentProvider
                            appState: appState,
                            showApiKeyHelp: $showApiKeyHelp
                        )
                        .padding(.top, 8)
                    }
                    .padding(.vertical, 10)
                    
                    // Preferences
                    VStack(alignment: .leading) {
                        Text("Preferences")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack {
                            Toggle("Enable Haptic Feedback", isOn: $enableHaptics)
                                .padding()
                            
                            NavigationLink(destination: CommandsView(commandsManager: commandsManager)) {
                                HStack {
                                    Image(systemName: "list.bullet.rectangle")
                                        .foregroundColor(.blue)
                                    Text("Manage AI Commands")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                                .padding()
                            }
                        }
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // About section
                    VStack(alignment: .leading) {
                        Text("About")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 0) {
                            // GitHub Link
                            Link(destination: URL(string: "https://github.com/Aryamirsepasi/WritingToolsKeyboard")!) {
                                HStack {
                                    Image(systemName: "globe.badge.chevron.backward")
                                        .font(.system(size: 22))
                                        .foregroundColor(.blue)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("View on GitHub")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        Text("Open source repository")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "arrow.up.right.square")
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal)
                            }
                            
                            Divider()
                                .padding(.leading, 56)
                            
                            // Developer website
                            Link(destination: URL(string: "https://aryamirsepasi.com/prosekey")!) {
                                HStack {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(.blue)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("App Website")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        Text("Arya Mirsepasi")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "arrow.up.right.square")
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal)
                            }
                            
                            Divider()
                                .padding(.leading, 56)
                            
                            // How to use
                            Link(destination: URL(string: "https://aryamirsepasi.com/support")!) {
                                HStack {
                                    Image(systemName: "questionmark.circle.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(.blue)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Having Issues?")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        Text("Submit a new issue on the support page!")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "arrow.up.right.square")
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal)
                            }
                            
                            Divider()
                                .padding(.leading, 56)
                            
                            // Privacy Policy
                            Link(destination: URL(string: "https://aryamirsepasi.com/prosekey/privacy")!) {
                                HStack {
                                    Image(systemName: "lock.shield.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(.blue)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Privacy Policy")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        Text("How your data is handled")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "arrow.up.right.square")
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal)
                            }
                            
                            // Version info with nicer layout
                            VStack(spacing: 4) {
                                Text("ProseKey AI")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text("Version 1.1")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text("© 2025 Arya Mirsepasi")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                        }
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                }
                .padding(.bottom, 30)
            }
            .navigationTitle("ProseKey AI")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            checkKeyboardStatus()
            
            if !hasCompletedOnboarding {
                showOnboarding = true
            }
            // Ensure AppState's current provider is in sync with AppSettings on appear
            appState.setCurrentProvider(settings.currentProvider)
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView()
        }
        .sheet(isPresented: $showApiKeyHelp) {
            ApiKeyHelpView(provider: settings.currentProvider) // Use settings.currentProvider
        }
    }
    
    private func openKeyboardSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Supporting Components

struct KeyboardStatusCard: View {
    let isEnabled: Bool
    let onEnablePressed: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: isEnabled ? "keyboard.badge.ellipsis" : "keyboard")
                    .font(.system(size: 24))
                    .foregroundColor(isEnabled ? .green : .orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Keyboard Status")
                        .font(.headline)
                    Text(isEnabled ? "Ready to use" : "Setup required")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isEnabled {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 24))
                } else {
                    Button(action: onEnablePressed) {
                        Text("Enable")
                            .fontWeight(.medium)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
            
            if !isEnabled {
                VStack(alignment: .leading, spacing: 8) {
                    SetupStepView(number: 1, text: "Open Settings", isCompleted: false)
                    SetupStepView(number: 2, text: "Go to General → Keyboard → Keyboards", isCompleted: false)
                    SetupStepView(number: 3, text: "Tap Add New Keyboard → Select ProseKey AI", isCompleted: false)
                    SetupStepView(number: 4, text: "Enable Full Access for AI features", isCompleted: false)
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct SetupStepView: View {
    let number: Int
    let text: String
    let isCompleted: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(isCompleted ? Color.green : Color.blue.opacity(0.2))
                    .frame(width: 24, height: 24)
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Text("\(number)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.blue)
                }
            }
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(isCompleted ? .secondary : .primary)
                .strikethrough(isCompleted)
        }
    }
}

struct ProviderTabView: View {
    @Binding var currentProvider: String
    
    private let providers: [(id: String, icon: String, name: String, color: Color)] = [
        ("gemini", "g.circle.fill", "Gemini", .blue),
        ("openai", "o.circle.fill", "OpenAI", .green),
        ("mistral", "m.circle.fill", "Mistral", .orange),
        ("anthropic", "a.circle.fill", "Anthropic", .purple),
        ("openrouter", "r.circle.fill", "OpenRouter", .pink)
    ]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(providers, id: \.id) { provider in
                    Button(action: { currentProvider = provider.id }) {
                        HStack(spacing: 6) {
                            Image(systemName: provider.icon)
                                .foregroundColor(provider.color)
                            Text(provider.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(currentProvider == provider.id ? provider.color.opacity(0.15) : Color(.systemGray6))
                        .foregroundColor(currentProvider == provider.id ? provider.color : .primary)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(currentProvider == provider.id ? provider.color : Color.clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
        }
    }
}


struct ProviderSetupCard: View {
    let provider: String
    @ObservedObject var appState: AppState
    @ObservedObject var settings = AppSettings.shared
    @Binding var showApiKeyHelp: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: providerIcon)
                    .font(.system(size: 22))
                    .foregroundColor(.blue)
                Text(providerName)
                    .font(.headline)
                Spacer()
                Button(action: { showApiKeyHelp = true }) {
                    Label("Help", systemImage: "questionmark.circle")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            HStack {
                Image(systemName: hasApiKey ? "checkmark.shield.fill" : "key.fill")
                    .foregroundColor(hasApiKey ? .green : .orange)
                Text(hasApiKey ? "API Key Configured" : "API Key Required")
                    .font(.subheadline)
                Spacer()
                // NavigationLinks for all providers
                switch provider {
                case "gemini":
                    NavigationLink(destination: GeminiSettingsView(appState: appState)) { Text(hasApiKey ? "Change" : "Configure").foregroundColor(.blue) }
                case "openai":
                    NavigationLink(destination: OpenAISettingsView(appState: appState)) { Text(hasApiKey ? "Change" : "Configure").foregroundColor(.blue) }
                case "mistral":
                    NavigationLink(destination: MistralSettingsView(appState: appState)) { Text(hasApiKey ? "Change" : "Configure").foregroundColor(.blue) }
                case "anthropic":
                    NavigationLink(destination: AnthropicSettingsView(appState: appState)) { Text(hasApiKey ? "Change" : "Configure").foregroundColor(.blue) }
                case "openrouter":
                    NavigationLink(destination: OpenRouterSettingsView(appState: appState)) { Text(hasApiKey ? "Change" : "Configure").foregroundColor(.blue) }
                default: EmptyView()
                }
            }
            Text(providerDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Link(destination: URL(string: apiKeyUrl)!) {
                HStack {
                    Text("Get \(providerName) API Key")
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                }
                .padding(12)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private var providerIcon: String {
        switch provider {
        case "gemini": return "g.circle.fill"
        case "openai": return "o.circle.fill"
        case "mistral": return "m.circle.fill"
        case "anthropic": return "a.circle.fill"
        case "openrouter": return "r.circle.fill"
        default: return "questionmark"
        }
    }
    private var providerName: String {
        switch provider {
        case "gemini": return "Google Gemini"
        case "openai": return "OpenAI"
        case "mistral": return "Mistral AI"
        case "anthropic": return "Anthropic"
        case "openrouter": return "OpenRouter"
        default: return "Unknown Provider"
        }
    }
    private var hasApiKey: Bool {
        switch provider {
        case "gemini": return !settings.geminiApiKey.isEmpty
        case "openai": return !settings.openAIApiKey.isEmpty
        case "mistral": return !settings.mistralApiKey.isEmpty
        case "anthropic": return !settings.anthropicApiKey.isEmpty
        case "openrouter": return !settings.openRouterApiKey.isEmpty
        default: return false
        }
    }
    private var providerDescription: String {
        switch provider {
        case "gemini": return "Google Gemini is a versatile AI model optimized for creative writing and text processing tasks. It provides high-quality completions and reformulations."
        case "openai": return "OpenAI offers powerful language models like GPT-4 that excel at understanding context and generating human-like text for various writing tasks."
        case "mistral": return "Mistral AI delivers efficient language models that balance performance and speed, great for text transformations and creative writing assistance."
        case "anthropic": return "Anthropic's Claude models are known for their safety and helpfulness, offering advanced language capabilities for writing and productivity."
        case "openrouter": return "OpenRouter is a gateway to many top AI models, letting you choose from a variety of providers with a single API key."
        default: return ""
        }
    }
    private var apiKeyUrl: String {
        switch provider {
        case "gemini": return "https://ai.google.dev/tutorials/setup"
        case "openai": return "https://platform.openai.com/account/api-keys"
        case "mistral": return "https://console.mistral.ai/api-keys/"
        case "anthropic": return "https://console.anthropic.com/settings/keys"
        case "openrouter": return "https://openrouter.ai/keys"
        default: return "https://example.com"
        }
    }
}


// MARK: - Help Sheets

struct ApiKeyHelpView: View {
    let provider: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header image
                    Image(systemName: providerIcon)
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 20)
                    
                    // Title
                    Text("How to Get Your \(providerName) API Key")
                        .font(.title2)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.bottom, 10)
                    
                    // Step-by-step instructions
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("\(index + 1).")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                                
                                Text(step.title)
                                    .font(.headline)
                            }
                            
                            Text(step.description)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .padding(.bottom, 8)
                    }
                    
                    // Notes and tips
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Important Notes:")
                            .font(.headline)
                            .padding(.top, 8)
                        
                        ForEach(notes, id: \.self) { note in
                            HStack(alignment: .top) {
                                Image(systemName: "exclamationmark.circle")
                                    .foregroundColor(.orange)
                                    .font(.system(size: 14))
                                    .frame(width: 20)
                                
                                Text(note)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Button to open provider website
                    Link(destination: URL(string: apiKeyUrl)!) {
                        Text("Go to \(providerName) API Key Page")
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.top, 12)
                }
                .padding()
            }
            .navigationTitle("API Key Guide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var providerIcon: String {
            switch provider {
            case "gemini": return "g.circle.fill"
            case "openai": return "o.circle.fill"
            case "mistral": return "m.circle.fill"
            case "anthropic": return "a.circle.fill"
            case "openrouter": return "r.circle.fill"
            default: return "questionmark"
            }
        }
    
    private var providerName: String {
            switch provider {
            case "gemini": return "Google Gemini"
            case "openai": return "OpenAI"
            case "mistral": return "Mistral AI"
            case "anthropic": return "Anthropic"
            case "openrouter": return "OpenRouter"
            default: return "Unknown Provider"
            }
        }
    
    private var apiKeyUrl: String {
            switch provider {
            case "gemini": return "https://ai.google.dev/tutorials/setup"
            case "openai": return "https://platform.openai.com/account/api-keys"
            case "mistral": return "https://console.mistral.ai/api-keys/"
            case "anthropic": return "https://console.anthropic.com/settings/keys"
            case "openrouter": return "https://openrouter.ai/keys"
            default: return "https://example.com"
            }
        }
    
    private var steps: [(title: String, description: String)] {
        switch provider {
        case "gemini":
            return [
                (title: "Create a Google AI Studio account",
                 description: "Visit ai.google.dev and sign in with your Google account."),
                (title: "Navigate to API keys",
                 description: "In Google AI Studio, click on 'Get API key' or go to the API section."),
                (title: "Create an API key",
                 description: "Click 'Create API Key' and give it a descriptive name like 'ProseKey Integration'."),
                (title: "Copy your API key",
                 description: "Copy the generated API key - you'll need to paste it into this app."),
                (title: "Enter the API key in ProseKey AI",
                 description: "Return to this app and paste the key in the Gemini settings section.")
            ]
            
        case "openai":
            return [
                (title: "Create an OpenAI account",
                 description: "Go to platform.openai.com and sign up or log in to your account."),
                (title: "Navigate to API section",
                 description: "Go to your account settings and select 'API keys'."),
                (title: "Create a new API key",
                 description: "Click 'Create new secret key' and provide a name like 'ProseKey Keyboard'."),
                (title: "Copy your API key",
                 description: "Copy the generated key immediately - OpenAI will only show it once."),
                (title: "Enter the API key in ProseKey AI",
                 description: "Return to this app and paste the key in the OpenAI settings section.")
            ]
            
        case "mistral":
            return [
                (title: "Create a Mistral AI account",
                 description: "Visit console.mistral.ai and sign up or log in."),
                (title: "Go to API Keys section",
                 description: "Navigate to the API Keys section in the console."),
                (title: "Generate a new API key",
                 description: "Click 'Create API Key' and give it a name like 'ProseKey App'."),
                (title: "Copy your API key",
                 description: "Copy the API key that appears - it won't be shown again."),
                (title: "Enter the API key in ProseKey AI",
                 description: "Return to this app and paste the key in the Mistral settings section.")
            ]
            
        case "anthropic":
            return [
                (title: "Create an Anthropic account", description: "Go to console.anthropic.com and sign up or log in."),
                (title: "Go to API Keys", description: "Navigate to the API Keys section in your account settings."),
                (title: "Create a new API key", description: "Click 'Create Key', give it a name, and copy it."),
                (title: "Enter the API key in ProseKey AI", description: "Paste the key in the Anthropic settings section.")
            ]
        case "openrouter":
            return [
                (title: "Create an OpenRouter account", description: "Go to openrouter.ai and sign up or log in."),
                (title: "Go to API Keys", description: "Navigate to the API Keys section."),
                (title: "Create a new API key", description: "Click 'Create Key', give it a name, and copy it."),
                (title: "Enter the API key in ProseKey AI", description: "Paste the key in the OpenRouter settings section.")
            ]
        default: return []
        }
    }
    
    private var notes: [String] {
        switch provider {
        case "gemini":
            return [
                "Your API key grants access to Google's AI services and may incur charges.",
                "Keep your API key confidential and never share it publicly.",
                "The free tier includes a generous amount of usage credits each month.",
                "Your API key is stored only on your device and is not sent to our servers."
            ]
            
        case "openai":
            return [
                "OpenAI API usage is billed based on the number of tokens processed.",
                "Set usage limits in your OpenAI account to control costs.",
                "Your API key is sensitive information - never share it publicly.",
                "If you need to revoke access, you can delete the key from your OpenAI account."
            ]
            
        case "mistral":
            return [
                "Mistral AI may charge based on your API usage beyond free tier limits.",
                "Check Mistral's pricing page for current rates and free tier allowances.",
                "Your API key should be kept secure and not shared with others.",
                "The app stores your key locally only and does not share it with any third parties."
            ]
            
        case "anthropic":
            return [
                "Anthropic API usage may be billed based on your plan.",
                "Keep your API key secure and do not share it.",
                "Your API key is stored only on your device."
            ]
        case "openrouter":
            return [
                "OpenRouter lets you access many models with one key.",
                "Check your usage and billing in your OpenRouter dashboard.",
                "Your API key is stored only on your device."
            ]
        default:
            return []
        }
    }
}
