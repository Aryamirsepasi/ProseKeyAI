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
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
            }
        }
        .padding(.bottom, 8)
    }
}

struct GeminiSettingsView: View {
    @ObservedObject var appState: AppState
    @State private var apiKey: String
    @State private var modelSelection: GeminiModel
    @State private var customModel: String
    
    init(appState: AppState) {
        self.appState = appState
        let settings = AppSettings.shared
        _apiKey = State(initialValue: settings.geminiApiKey)
        _modelSelection = State(initialValue: settings.geminiModel)
        _customModel = State(initialValue: settings.geminiCustomModel)
    }
    
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
                    text: $apiKey,
                    isSecure: true
                )
                
                // Model selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Model")
                        .font(.headline)
                    
                    VStack {
                        Picker("Model", selection: $modelSelection) {
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
                }
                
                // Custom model name field (conditional)
                if modelSelection == .custom {
                    LabeledTextField(
                        label: "Custom Model Name",
                        placeholder: "Enter custom model identifier",
                        text: $customModel
                    )
                    .transition(.opacity)
                }
                
                // Save button
                Button(action: {
                    appState.saveGeminiConfig(
                        apiKey: apiKey,
                        model: modelSelection,
                        customModelName: customModel
                    )
                }) {
                    Text("Save Changes")
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            isFormValid ? Color.blue : Color.gray
                        )
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
        !apiKey.isEmpty && (modelSelection != .custom || !customModel.isEmpty)
    }
}


struct OpenAISettingsView: View {
    @ObservedObject var appState: AppState
    @State private var apiKey: String
    @State private var baseURL: String
    @State private var modelName: String
    
    init(appState: AppState) {
        self.appState = appState
        let settings = AppSettings.shared
        _apiKey = State(initialValue: settings.openAIApiKey)
        _baseURL = State(initialValue: settings.openAIBaseURL)
        _modelName = State(initialValue: settings.openAIModel)
    }
    
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
                    text: $apiKey,
                    isSecure: true
                )
                
                // Base URL field
                LabeledTextField(
                    label: "Base URL",
                    placeholder: "https://api.openai.com",
                    text: $baseURL
                )
                
                // Model field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Model")
                        .font(.headline)
                    
                    VStack {
                        TextField("gpt-4o", text: $modelName)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                    }
                }
                
                // Suggested models
                VStack(alignment: .leading, spacing: 10) {
                    Text("Suggested Models:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ForEach(OpenAIModel.allCases, id: \.self) { model in
                        Button(action: {
                            modelName = model.rawValue
                        }) {
                            HStack {
                                Text(model.displayName)
                                    .font(.subheadline)
                                
                                Spacer()
                                
                                if modelName == model.rawValue {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(
                                modelName == model.rawValue ?
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
                
                // Save button
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
                        .background(
                            isFormValid ? Color.blue : Color.gray
                        )
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
        !apiKey.isEmpty && !baseURL.isEmpty && !modelName.isEmpty
    }
}

struct MistralSettingsView: View {
    @ObservedObject var appState: AppState
    @State private var apiKey: String
    @State private var modelSelection: String
    
    init(appState: AppState) {
        self.appState = appState
        let settings = AppSettings.shared
        _apiKey = State(initialValue: settings.mistralApiKey)
        _modelSelection = State(initialValue: settings.mistralModel)
    }
    
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
                    text: $apiKey,
                    isSecure: true
                )
                
                // Model selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Model")
                        .font(.headline)
                    
                    VStack {
                        Picker("Model", selection: $modelSelection) {
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
                }
                
                // Save button
                Button(action: {
                    appState.saveMistralConfig(
                        apiKey: apiKey,
                        model: modelSelection
                    )
                }) {
                    Text("Save Changes")
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            !apiKey.isEmpty ? Color.blue : Color.gray
                        )
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(apiKey.isEmpty)
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
