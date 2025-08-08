import SwiftUI

struct LabeledTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.headline)
                .foregroundColor(.primary)
            
            if isSecure {
                SecureField(placeholder, text: $text)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
            } else {
                TextField(placeholder, text: $text)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
        }
        .padding(.bottom, 8)
    }
}

struct GeminiSettingsView: View {
    @ObservedObject var appState: AppState
    @ObservedObject var settings = AppSettings.shared
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Image(systemName: "g.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading) {
                        Text("Google Gemini")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Configure your Gemini API access")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.bottom, 20)
                
                // API Key field
                LabeledTextField(
                    label: "API Key",
                    placeholder: "Enter your Gemini API key",
                    text: $settings.geminiApiKey,
                    isSecure: true
                )
                
                // Model selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Model")
                        .font(.headline)
                    Picker("Model", selection: $settings.geminiModel) { // Bind directly
                        ForEach(GeminiModel.allCases, id: \.self) { model in
                            Text(model.displayName).tag(model)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
                
                // Custom model name field (conditional)
                if settings.geminiModel == .custom {
                    LabeledTextField(
                        label: "Custom Model Name",
                        placeholder: "Enter custom model identifier",
                        text: $settings.geminiCustomModel // Bind directly
                    )
                    .transition(.opacity)
                }
                
                Button(action: {
                    appState.saveGeminiConfig(
                        apiKey: settings.geminiApiKey,
                        model: settings.geminiModel,
                        customModelName: settings.geminiCustomModel
                    )
                    // Consider adding user feedback, e.g., an alert or dismiss action
                }) {
                    Text("Save Changes")
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(!isFormValid)
                .padding(.top, 20)
                
                // Help text
                VStack(alignment: .leading, spacing: 8) {
                    Text("Getting a Gemini API Key:")
                        .font(.headline)
                        .padding(.top, 8)
                    
                    HStack(alignment: .top) {
                        Image(systemName: "1.circle.fill")
                            .foregroundColor(.blue)
                        Text("Visit Google AI Studio (ai.google.dev)")
                    }
                    
                    HStack(alignment: .top) {
                        Image(systemName: "2.circle.fill")
                            .foregroundColor(.blue)
                        Text("Sign in with your Google account")
                    }
                    
                    HStack(alignment: .top) {
                        Image(systemName: "3.circle.fill")
                            .foregroundColor(.blue)
                        Text("Go to API → Get API Key")
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.top, 20)
            }
            .padding()
        }
        .navigationTitle("Gemini Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var isFormValid: Bool {
        !settings.geminiApiKey.isEmpty &&
        (settings.geminiModel != .custom || !settings.geminiCustomModel.isEmpty)
    }
}


struct OpenAISettingsView: View {
    @ObservedObject var appState: AppState
    @ObservedObject var settings = AppSettings.shared
    
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Image(systemName: "o.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading) {
                        Text("OpenAI")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Configure your OpenAI API access")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.bottom, 20)
                
                // API Key field
                LabeledTextField(
                    label: "API Key",
                    placeholder: "Enter your OpenAI API key",
                    text: $settings.openAIApiKey, // Bind directly
                    isSecure: true
                )
                
                LabeledTextField(
                    label: "Base URL",
                    placeholder: "https://api.openai.com",
                    text: $settings.openAIBaseURL // Bind directly
                )
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Model")
                        .font(.headline)
                    TextField("gpt-4o", text: $settings.openAIModel) // Bind directly
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                }
                
                // Suggested models
                VStack(alignment: .leading, spacing: 10) {
                    Text("Suggested Models:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    ForEach(OpenAIModel.allCases, id: \.self) { model in
                        Button(action: {
                            settings.openAIModel = model.rawValue // Update settings directly
                        }) {
                            HStack {
                                Text(model.displayName)
                                    .font(.subheadline)
                                Spacer()
                                if settings.openAIModel == model.rawValue { // Check settings
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(
                                settings.openAIModel == model.rawValue ?
                                Color.blue.opacity(0.1) : Color.clear
                            )
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                Button(action: {
                    appState.saveOpenAIConfig(
                        apiKey: settings.openAIApiKey,
                        baseURL: settings.openAIBaseURL,
                        model: settings.openAIModel
                    )
                }) {
                    Text("Save Changes")
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(!isFormValid)
                .padding(.top, 20)
                
                // Help section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Getting an OpenAI API Key:")
                        .font(.headline)
                        .padding(.top, 8)
                    
                    HStack(alignment: .top) {
                        Image(systemName: "1.circle.fill")
                            .foregroundColor(.blue)
                        Text("Go to platform.openai.com")
                    }
                    
                    HStack(alignment: .top) {
                        Image(systemName: "2.circle.fill")
                            .foregroundColor(.blue)
                        Text("Select API keys from settings")
                    }
                    
                    HStack(alignment: .top) {
                        Image(systemName: "3.circle.fill")
                            .foregroundColor(.blue)
                        Text("Create a new secret key")
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.top, 20)
            }
            .padding()
        }
        .navigationTitle("OpenAI Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var isFormValid: Bool {
        !settings.openAIApiKey.isEmpty &&
        !settings.openAIBaseURL.isEmpty &&
        !settings.openAIModel.isEmpty
    }
}

struct MistralSettingsView: View {
    @ObservedObject var appState: AppState
    @ObservedObject var settings = AppSettings.shared
    
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Image(systemName: "m.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading) {
                        Text("Mistral AI")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Configure your Mistral API access")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.bottom, 20)
                
                // API Key field
                LabeledTextField(
                    label: "API Key",
                    placeholder: "Enter your Mistral API key",
                    text: $settings.mistralApiKey, // Bind directly
                    isSecure: true
                )
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Model")
                        .font(.headline)
                    Picker("Model", selection: $settings.mistralModel) { // Bind directly
                        ForEach(MistralModel.allCases, id: \.self) { model in
                            Text(model.displayName).tag(model.rawValue)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
                
                Button(action: {
                    appState.saveMistralConfig(
                        apiKey: settings.mistralApiKey,
                        model: settings.mistralModel
                    )
                }) {
                    Text("Save Changes")
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            !settings.mistralApiKey.isEmpty ? Color.blue : Color.gray
                        )
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(settings.mistralApiKey.isEmpty) // Validation based on settings
                .padding(.top, 20)
                
                // Help info
                VStack(alignment: .leading, spacing: 8) {
                    Text("Getting a Mistral API Key:")
                        .font(.headline)
                        .padding(.top, 8)
                    
                    HStack(alignment: .top) {
                        Image(systemName: "1.circle.fill")
                            .foregroundColor(.blue)
                        Text("Visit console.mistral.ai")
                    }
                    
                    HStack(alignment: .top) {
                        Image(systemName: "2.circle.fill")
                            .foregroundColor(.blue)
                        Text("Sign up or log in to your account")
                    }
                    
                    HStack(alignment: .top) {
                        Image(systemName: "3.circle.fill")
                            .foregroundColor(.blue)
                        Text("Navigate to API Keys and create a new key")
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.top, 20)
            }
            .padding()
        }
        .navigationTitle("Mistral Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AnthropicSettingsView: View {
    @ObservedObject var appState: AppState
    @ObservedObject var settings = AppSettings.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Image(systemName: "a.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.purple)
                    VStack(alignment: .leading) {
                        Text("Anthropic Claude")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Configure your Anthropic API access")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.bottom, 20)
                LabeledTextField(
                    label: "API Key",
                    placeholder: "Enter your Anthropic API key",
                    text: $settings.anthropicApiKey,
                    isSecure: true
                )
                LabeledTextField(
                    label: "Model",
                    placeholder: AnthropicConfig.defaultModel,
                    text: $settings.anthropicModel
                )
                Button(action: {
                    appState.saveAnthropicConfig(
                        apiKey: settings.anthropicApiKey,
                        model: settings.anthropicModel
                    )
                }) {
                    Text("Save Changes")
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(!settings.anthropicApiKey.isEmpty ? Color.purple : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(settings.anthropicApiKey.isEmpty)
                .padding(.top, 20)
                // Help text...
            }
            .padding()
        }
        .navigationTitle("Anthropic Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct OpenRouterSettingsView: View {
    @ObservedObject var appState: AppState
    @ObservedObject var settings = AppSettings.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Image(systemName: "r.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.pink)
                    VStack(alignment: .leading) {
                        Text("OpenRouter")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Configure your OpenRouter API access")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.bottom, 20)
                LabeledTextField(
                    label: "API Key",
                    placeholder: "Enter your OpenRouter API key",
                    text: $settings.openRouterApiKey,
                    isSecure: true
                )
                LabeledTextField(
                    label: "Model",
                    placeholder: OpenRouterConfig.defaultModel,
                    text: $settings.openRouterModel
                )
                Button(action: {
                    appState.saveOpenRouterConfig(
                        apiKey: settings.openRouterApiKey,
                        model: settings.openRouterModel
                    )
                }) {
                    Text("Save Changes")
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(!settings.openRouterApiKey.isEmpty ? Color.pink : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(settings.openRouterApiKey.isEmpty)
                .padding(.top, 20)
                // Help text...
            }
            .padding()
        }
        .navigationTitle("OpenRouter Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}
