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
                    .textInputAutocapitalization(.never)
                    .textContentType(.password)
                    .autocorrectionDisabled()
            } else {
                TextField(placeholder, text: $text)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .textInputAutocapitalization(.never)
                    .textContentType(.none)
                    .autocorrectionDisabled()
            }
        }
        .padding(.bottom, 8)
    }
}

struct GeminiSettingsView: View {
    @ObservedObject var appState: AppState
    @State private var apiKey: String = AppSettings.shared.geminiApiKey
    @State private var modelName: String = {
        let current = AppSettings.shared.geminiModel
        return current == .custom ? AppSettings.shared.geminiCustomModel : current.rawValue
    }()
    @State private var suggested: GeminiModel = AppSettings.shared.geminiModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Image("google")
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 36, height: 36)
                        .foregroundColor(Color(hex: "4285F4"))
                    
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
                    text: $apiKey,
                    isSecure: true
                )
                
                // Free-form model name input
                LabeledTextField(
                    label: "Model",
                    placeholder: "e.g. gemini-1.5-flash",
                    text: $modelName
                )
                .onChange(of: modelName) { newValue in
                    if let matched = GeminiModel(rawValue: newValue) {
                        suggested = matched
                    } else {
                        suggested = .custom
                    }
                }
                
                // Suggested models (picker)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Suggested Models")
                        .font(.headline)
                    Picker("Suggested Models", selection: $suggested) {
                        ForEach(GeminiModel.allCases, id: \.self) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: suggested) { newValue in
                        if newValue != .custom {
                            modelName = newValue.rawValue
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
                
                Button(action: {
                    let resolvedModel: GeminiModel
                    let custom: String
                    if let match = GeminiModel(rawValue: modelName) {
                        resolvedModel = match
                        custom = ""
                    } else {
                        resolvedModel = .custom
                        custom = modelName
                    }
                    appState.saveGeminiConfig(
                        apiKey: apiKey,
                        model: resolvedModel,
                        customModelName: custom
                    )
                    // Consider adding user feedback, e.g., an alert or dismiss action
                }) {
                    Text("Save Changes")
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? Color(hex: "4285F4") : Color.gray)
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
                            .foregroundColor(Color(hex: "4285F4"))
                        Text("Visit Google AI Studio (ai.google.dev)")
                    }
                    
                    HStack(alignment: .top) {
                        Image(systemName: "2.circle.fill")
                            .foregroundColor(Color(hex: "4285F4"))
                        Text("Sign in with your Google account")
                    }
                    
                    HStack(alignment: .top) {
                        Image(systemName: "3.circle.fill")
                            .foregroundColor(Color(hex: "4285F4"))
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
        // Allow empty API key to clear it; require a non-empty model name
        !modelName.isEmpty
    }
}


struct OpenAISettingsView: View {
    @ObservedObject var appState: AppState
    @State private var apiKey: String = AppSettings.shared.openAIApiKey
    @State private var baseURL: String = AppSettings.shared.openAIBaseURL
    @State private var modelName: String = AppSettings.shared.openAIModel
    private enum SuggestedOpenAI: Hashable {
        case custom
        case model(OpenAIModel)
    }
    @State private var suggested: SuggestedOpenAI = {
        if let match = OpenAIModel(rawValue: AppSettings.shared.openAIModel) {
            return .model(match)
        } else {
            return .custom
        }
    }()
    
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Image("openai")
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 36, height: 36)
                        .foregroundColor(.white)
                    
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
                    text: $apiKey,
                    isSecure: true
                )
                
                LabeledTextField(
                    label: "Base URL",
                    placeholder: "https://api.openai.com",
                    text: $baseURL
                )
                
                // Free-form model name input
                LabeledTextField(
                    label: "Model",
                    placeholder: "gpt-5-mini",
                    text: $modelName
                )
                .onChange(of: modelName) { newValue in
                    if let matched = OpenAIModel(rawValue: newValue) {
                        suggested = .model(matched)
                    } else {
                        suggested = .custom
                    }
                }
                
                // Suggested models (picker)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Suggested Models")
                        .font(.headline)
                    Picker("Suggested Models", selection: $suggested) {
                        Text("Custom").tag(SuggestedOpenAI.custom)
                        ForEach(OpenAIModel.allCases, id: \.self) { option in
                            Text(option.displayName).tag(SuggestedOpenAI.model(option))
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: suggested) { newValue in
                        if case let .model(m) = newValue {
                            modelName = m.rawValue
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
                
                Button(action: {
                    appState.saveOpenAIConfig(
                        apiKey: apiKey,
                        baseURL: baseURL,
                        model: modelName
                    )
                }) {
                    Text("Save Changes")
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? Color(hex: "412991") : Color.gray)
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
                            .foregroundColor(Color(hex: "412991"))
                        Text("Go to platform.openai.com")
                    }
                    
                    HStack(alignment: .top) {
                        Image(systemName: "2.circle.fill")
                            .foregroundColor(Color(hex: "412991"))
                        Text("Select API keys from settings")
                    }
                    
                    HStack(alignment: .top) {
                        Image(systemName: "3.circle.fill")
                            .foregroundColor(Color(hex: "412991"))
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
        // Allow empty API key to clear it; require baseURL and model to avoid invalid config
        !baseURL.isEmpty && !modelName.isEmpty
    }
}

struct MistralSettingsView: View {
    @ObservedObject var appState: AppState
    @State private var apiKey: String = AppSettings.shared.mistralApiKey
    @State private var modelName: String = AppSettings.shared.mistralModel
    private enum SuggestedMistral: Hashable {
        case custom
        case model(MistralModel)
    }
    @State private var suggested: SuggestedMistral = {
        if let match = MistralModel(rawValue: AppSettings.shared.mistralModel) {
            return .model(match)
        } else {
            return .custom
        }
    }()
    
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Image("mistralai")
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 36, height: 36)
                        .foregroundColor(Color(hex: "FA520F"))
                    
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
                    text: $apiKey,
                    isSecure: true
                )
                
                // Free-form model name input
                LabeledTextField(
                    label: "Model",
                    placeholder: MistralConfig.defaultModel,
                    text: $modelName
                )
                .onChange(of: modelName) { newValue in
                    if let matched = MistralModel(rawValue: newValue) {
                        suggested = .model(matched)
                    } else {
                        suggested = .custom
                    }
                }

                // Suggested models (picker)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Suggested Models")
                        .font(.headline)
                    Picker("Suggested Models", selection: $suggested) {
                        Text("Custom").tag(SuggestedMistral.custom)
                        ForEach(MistralModel.allCases, id: \.self) { option in
                            Text(option.displayName).tag(SuggestedMistral.model(option))
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: suggested) { newValue in
                        if case let .model(m) = newValue {
                            modelName = m.rawValue
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
                
                Button(action: {
                    appState.saveMistralConfig(
                        apiKey: apiKey,
                        model: modelName
                    )
                }) {
                    Text("Save Changes")
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? Color(hex: "FA520F") : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(!isFormValid)
                .padding(.top, 20)
                
                // Help info
                VStack(alignment: .leading, spacing: 8) {
                    Text("Getting a Mistral API Key:")
                        .font(.headline)
                        .padding(.top, 8)
                    
                    HStack(alignment: .top) {
                        Image(systemName: "1.circle.fill")
                            .foregroundColor(Color(hex: "FA520F"))
                        Text("Visit console.mistral.ai")
                    }
                    
                    HStack(alignment: .top) {
                        Image(systemName: "2.circle.fill")
                            .foregroundColor(Color(hex: "FA520F"))
                        Text("Sign up or log in to your account")
                    }
                    
                    HStack(alignment: .top) {
                        Image(systemName: "3.circle.fill")
                            .foregroundColor(Color(hex: "FA520F"))
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
    
    private var isFormValid: Bool {
        !modelName.isEmpty
    }
}

struct AnthropicSettingsView: View {
    @ObservedObject var appState: AppState
    @State private var apiKey: String = AppSettings.shared.anthropicApiKey
    @State private var model: String = AppSettings.shared.anthropicModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Image("anthropic")
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 36, height: 36)
                        .foregroundColor(Color(hex: "c15f3c"))
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
                    text: $apiKey,
                    isSecure: true
                )
                LabeledTextField(
                    label: "Model",
                    placeholder: AnthropicConfig.defaultModel,
                    text: $model
                )
                Button(action: {
                    appState.saveAnthropicConfig(
                        apiKey: apiKey,
                        model: model
                    )
                }) {
                    Text("Save Changes")
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(!model.isEmpty ? Color(hex: "c15f3c") : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(model.isEmpty)
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
    @State private var apiKey: String = AppSettings.shared.openRouterApiKey
    @State private var model: String = AppSettings.shared.openRouterModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Image(systemName: "o.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(Color(hex: "7FADF2"))
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
                    text: $apiKey,
                    isSecure: true
                )
                LabeledTextField(
                    label: "Model",
                    placeholder: OpenRouterConfig.defaultModel,
                    text: $model
                )
                Button(action: {
                    appState.saveOpenRouterConfig(
                        apiKey: apiKey,
                        model: model
                    )
                }) {
                    Text("Save Changes")
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(!model.isEmpty ? Color(hex: "7FADF2") : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(model.isEmpty)
                .padding(.top, 20)
                // Help text...
            }
            .padding()
        }
        .navigationTitle("OpenRouter Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PerplexitySettingsView: View {
    @ObservedObject var appState: AppState
    @State private var apiKey: String = AppSettings.shared.perplexityApiKey
    @State private var model: String = AppSettings.shared.perplexityModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Image("perplexity")
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 36, height: 36)
                        .foregroundColor(Color(hex: "1FB8CD"))
                    VStack(alignment: .leading) {
                        Text("Perplexity")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Configure your Perplexity API access")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.bottom, 20)

                // API Key field
                LabeledTextField(
                    label: "API Key",
                    placeholder: "Enter your Perplexity API key",
                    text: $apiKey,
                    isSecure: true
                )

                // Model field
                LabeledTextField(
                    label: "Model",
                    placeholder: PerplexityConfig.defaultModel,
                    text: $model
                )

                Button(action: {
                    appState.savePerplexityConfig(
                        apiKey: apiKey,
                        model: model
                    )
                }) {
                    Text("Save Changes")
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(!model.isEmpty ? Color(hex: "1FB8CD") : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(model.isEmpty)
                .padding(.top, 20)

                // Optional help section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Getting a Perplexity API Key:")
                        .font(.headline)
                        .padding(.top, 8)

                    HStack(alignment: .top) {
                        Image(systemName: "1.circle.fill")
                            .foregroundColor(Color(hex: "1FB8CD"))
                        Text("Visit perplexity.ai and create an account")
                    }

                    HStack(alignment: .top) {
                        Image(systemName: "2.circle.fill")
                            .foregroundColor(Color(hex: "1FB8CD"))
                        Text("Navigate to your account/API keys page")
                    }

                    HStack(alignment: .top) {
                        Image(systemName: "3.circle.fill")
                            .foregroundColor(Color(hex: "1FB8CD"))
                        Text("Create a new API key and copy it")
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.top, 20)
            }
            .padding()
        }
        .navigationTitle("Perplexity Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

