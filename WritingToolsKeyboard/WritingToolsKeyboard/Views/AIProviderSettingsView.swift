import SwiftUI

// MARK: - Helpers
final class Debouncer {
    private var workItem: DispatchWorkItem?
    func schedule(after delay: TimeInterval = 0.5, _ block: @escaping () -> Void) {
        workItem?.cancel()
        let item = DispatchWorkItem(block: block)
        workItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: item)
    }
}

struct SavedToast: View {
    @Binding var isVisible: Bool
    var body: some View {
        Group {
            if isVisible {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(.white)
                    Text("Saved").foregroundColor(.white).font(.subheadline).bold()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.green)
                .clipShape(Capsule())
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(response: 0.35, dampingFraction: 0.9), value: isVisible)
            }
        }
    }
}

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
    
    @State private var apiKey: String = ""
    @State private var selectedModel: GeminiModel = .twoflash
    @State private var customModel: String = ""
    @State private var showSavedToast: Bool = false
    @State private var debouncer = Debouncer()
    
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
                    Picker("Model", selection: $selectedModel) {
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
                if selectedModel == .custom {
                    LabeledTextField(
                        label: "Custom Model Name",
                        placeholder: "Enter custom model identifier",
                        text: $customModel
                    )
                    .transition(.opacity)
                }
                
                Button(action: {
                    appState.saveGeminiConfig(
                        apiKey: apiKey,
                        model: selectedModel,
                        customModelName: customModel
                    )
                    showSavedToastTemporarily()
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
        .onAppear {
            apiKey = settings.geminiApiKey
            selectedModel = settings.geminiModel
            customModel = settings.geminiCustomModel
        }
        .onChange(of: apiKey) { _ in scheduleAutoSave() }
        .onChange(of: selectedModel) { _ in scheduleAutoSave() }
        .onChange(of: customModel) { _ in scheduleAutoSave() }
        .navigationTitle("Gemini Settings")
        .navigationBarTitleDisplayMode(.inline)
        .overlay(SavedToast(isVisible: $showSavedToast), alignment: .top)
    }
    
    private func scheduleAutoSave() {
        guard isFormValid else { return }
        debouncer.schedule { saveIfNeeded() }
    }
    private func saveIfNeeded() {
        // Only save if values differ from persisted settings
        if settings.geminiApiKey != apiKey || settings.geminiModel != selectedModel || (selectedModel == .custom && settings.geminiCustomModel != customModel) {
            appState.saveGeminiConfig(apiKey: apiKey, model: selectedModel, customModelName: customModel)
            showSavedToastTemporarily()
        }
    }
    private func showSavedToastTemporarily() {
        withAnimation { showSavedToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation { showSavedToast = false }
        }
    }
    
    private var isFormValid: Bool {
        !apiKey.isEmpty &&
        (selectedModel != .custom || !customModel.isEmpty)
    }
}


struct OpenAISettingsView: View {
    @ObservedObject var appState: AppState
    @ObservedObject var settings = AppSettings.shared
    
    @State private var apiKey: String = ""
    @State private var baseURL: String = ""
    @State private var model: String = ""
    @State private var showSavedToast: Bool = false
    @State private var debouncer = Debouncer()
    
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
                
                LabeledTextField(
                    label: "Base URL",
                    placeholder: "https://api.openai.com",
                    text: $baseURL
                )
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Model")
                        .font(.headline)
                    TextField("gpt-4o", text: $model)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                
                // Suggested models
                VStack(alignment: .leading, spacing: 10) {
                    Text("Suggested Models:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    ForEach(OpenAIModel.allCases, id: \.self) { candidate in
                        Button(action: {
                            model = candidate.rawValue
                        }) {
                            HStack {
                                Text(candidate.displayName)
                                    .font(.subheadline)
                                Spacer()
                                if model == candidate.rawValue {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(
                                model == candidate.rawValue ?
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
                        apiKey: apiKey,
                        baseURL: baseURL,
                        model: model
                    )
                    showSavedToastTemporarily()
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
        .onAppear {
            apiKey = settings.openAIApiKey
            baseURL = settings.openAIBaseURL
            model = settings.openAIModel
        }
        .onChange(of: apiKey) { _ in scheduleAutoSave() }
        .onChange(of: baseURL) { _ in scheduleAutoSave() }
        .onChange(of: model) { _ in scheduleAutoSave() }
        .navigationTitle("OpenAI Settings")
        .navigationBarTitleDisplayMode(.inline)
        .overlay(SavedToast(isVisible: $showSavedToast), alignment: .top)
    }
    
    private func scheduleAutoSave() {
        guard isFormValid else { return }
        debouncer.schedule { saveIfNeeded() }
    }
    private func saveIfNeeded() {
        if settings.openAIApiKey != apiKey || settings.openAIBaseURL != baseURL || settings.openAIModel != model {
            appState.saveOpenAIConfig(apiKey: apiKey, baseURL: baseURL, model: model)
            showSavedToastTemporarily()
        }
    }
    private func showSavedToastTemporarily() {
        withAnimation { showSavedToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation { showSavedToast = false }
        }
    }
    
    private var isFormValid: Bool {
        !apiKey.isEmpty &&
        !baseURL.isEmpty &&
        !model.isEmpty
    }
}

struct MistralSettingsView: View {
    @ObservedObject var appState: AppState
    @ObservedObject var settings = AppSettings.shared
    
    @State private var apiKey: String = ""
    @State private var model: String = MistralConfig.defaultModel
    @State private var showSavedToast: Bool = false
    @State private var debouncer = Debouncer()
    
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
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Model")
                        .font(.headline)
                    Picker("Model", selection: $model) {
                        ForEach(MistralModel.allCases, id: \.self) { modelCase in
                            Text(modelCase.displayName).tag(modelCase.rawValue)
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
                        apiKey: apiKey,
                        model: model
                    )
                    showSavedToastTemporarily()
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
        .onAppear {
            apiKey = settings.mistralApiKey
            model = settings.mistralModel
        }
        .onChange(of: apiKey) { _ in scheduleAutoSave() }
        .onChange(of: model) { _ in scheduleAutoSave() }
        .navigationTitle("Mistral Settings")
        .navigationBarTitleDisplayMode(.inline)
        .overlay(SavedToast(isVisible: $showSavedToast), alignment: .top)
    }
    
    private func scheduleAutoSave() {
        guard !apiKey.isEmpty else { return }
        debouncer.schedule { saveIfNeeded() }
    }
    private func saveIfNeeded() {
        if settings.mistralApiKey != apiKey || settings.mistralModel != model {
            appState.saveMistralConfig(apiKey: apiKey, model: model)
            showSavedToastTemporarily()
        }
    }
    private func showSavedToastTemporarily() {
        withAnimation { showSavedToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation { showSavedToast = false }
        }
    }
}

struct AnthropicSettingsView: View {
    @ObservedObject var appState: AppState
    @ObservedObject var settings = AppSettings.shared
    
    @State private var apiKey: String = ""
    @State private var model: String = AnthropicConfig.defaultModel
    @State private var showSavedToast: Bool = false
    @State private var debouncer = Debouncer()

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
                    showSavedToastTemporarily()
                }) {
                    Text("Save Changes")
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(!apiKey.isEmpty ? Color.purple : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(apiKey.isEmpty)
                .padding(.top, 20)
                // Help text...
            }
            .padding()
        }
        .onAppear {
            apiKey = settings.anthropicApiKey
            model = settings.anthropicModel
        }
        .onChange(of: apiKey) { _ in scheduleAutoSave() }
        .onChange(of: model) { _ in scheduleAutoSave() }
        .navigationTitle("Anthropic Settings")
        .navigationBarTitleDisplayMode(.inline)
        .overlay(SavedToast(isVisible: $showSavedToast), alignment: .top)
    }
    
    private func scheduleAutoSave() {
        guard !apiKey.isEmpty else { return }
        debouncer.schedule { saveIfNeeded() }
    }
    private func saveIfNeeded() {
        if settings.anthropicApiKey != apiKey || settings.anthropicModel != model {
            appState.saveAnthropicConfig(apiKey: apiKey, model: model)
            showSavedToastTemporarily()
        }
    }
    private func showSavedToastTemporarily() {
        withAnimation { showSavedToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation { showSavedToast = false }
        }
    }
}

struct OpenRouterSettingsView: View {
    @ObservedObject var appState: AppState
    @ObservedObject var settings = AppSettings.shared
    
    @State private var apiKey: String = ""
    @State private var model: String = OpenRouterConfig.defaultModel
    @State private var showSavedToast: Bool = false
    @State private var debouncer = Debouncer()

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
                    showSavedToastTemporarily()
                }) {
                    Text("Save Changes")
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(!apiKey.isEmpty ? Color.pink : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(apiKey.isEmpty)
                .padding(.top, 20)
                // Help text...
            }
            .padding()
        }
        .onAppear {
            apiKey = settings.openRouterApiKey
            model = settings.openRouterModel
        }
        .onChange(of: apiKey) { _ in scheduleAutoSave() }
        .onChange(of: model) { _ in scheduleAutoSave() }
        .navigationTitle("OpenRouter Settings")
        .navigationBarTitleDisplayMode(.inline)
        .overlay(SavedToast(isVisible: $showSavedToast), alignment: .top)
    }
    
    private func scheduleAutoSave() {
        guard !apiKey.isEmpty else { return }
        debouncer.schedule { saveIfNeeded() }
    }
    private func saveIfNeeded() {
        if settings.openRouterApiKey != apiKey || settings.openRouterModel != model {
            appState.saveOpenRouterConfig(apiKey: apiKey, model: model)
            showSavedToastTemporarily()
        }
    }
    private func showSavedToastTemporarily() {
        withAnimation { showSavedToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation { showSavedToast = false }
        }
    }
}

struct PerplexitySettingsView: View {
    @ObservedObject var appState: AppState
    @ObservedObject var settings = AppSettings.shared
    
    @State private var apiKey: String = ""
    @State private var model: String = PerplexityConfig.defaultModel
    @State private var showSavedToast: Bool = false
    @State private var debouncer = Debouncer()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Image(systemName: "p.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.blue)
                    VStack(alignment: .leading) {
                        Text("Perplexity")
                            .font(.title2).fontWeight(.bold)
                        Text("Configure your Perplexity API access")
                            .font(.subheadline).foregroundColor(.secondary)
                    }
                }
                .padding(.bottom, 20)

                // API Key
                LabeledTextField(
                    label: "API Key",
                    placeholder: "Enter your Perplexity API key",
                    text: $apiKey,
                    isSecure: true
                )

                // Model
                VStack(alignment: .leading, spacing: 8) {
                    Text("Model").font(.headline)
                    TextField(PerplexityConfig.defaultModel, text: $model)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                // Suggested models
                VStack(alignment: .leading, spacing: 10) {
                    Text("Suggested Models:")
                        .font(.subheadline).fontWeight(.medium)
                    ForEach(PerplexityModel.allCases, id: \.self) { candidate in
                        Button {
                            model = candidate.rawValue
                        } label: {
                            HStack {
                                Text(candidate.displayName).font(.subheadline)
                                Spacer()
                                if model == candidate.rawValue {
                                    Image(systemName: "checkmark").foregroundColor(.blue)
                                }
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(model == candidate.rawValue ? Color.blue.opacity(0.1) : Color.clear)
                            .cornerRadius(8)
                        }
                    }
                }

                Button {
                    appState.savePerplexityConfig(
                        apiKey: apiKey,
                        model: model
                    )
                    showSavedToastTemporarily()
                } label: {
                    Text("Save Changes")
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(apiKey.isEmpty ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(apiKey.isEmpty)

                // Help box
                VStack(alignment: .leading, spacing: 8) {
                    Text("Getting a Perplexity API Key:").font(.headline).padding(.top, 8)
                    Label("Go to perplexity.ai → Settings → API", systemImage: "1.circle.fill").foregroundColor(.blue)
                    Label("Create a key and copy it", systemImage: "2.circle.fill").foregroundColor(.blue)
                    Label("Paste the key above and Save", systemImage: "3.circle.fill").foregroundColor(.blue)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.top, 10)
            }
            .padding()
        }
        .onAppear {
            apiKey = settings.perplexityApiKey
            model = settings.perplexityModel
        }
        .onChange(of: apiKey) { _ in scheduleAutoSave() }
        .onChange(of: model) { _ in scheduleAutoSave() }
        .navigationTitle("Perplexity Settings")
        .navigationBarTitleDisplayMode(.inline)
        .overlay(SavedToast(isVisible: $showSavedToast), alignment: .top)
    }
    
    private func scheduleAutoSave() {
        guard !apiKey.isEmpty else { return }
        debouncer.schedule { saveIfNeeded() }
    }
    private func saveIfNeeded() {
        if settings.perplexityApiKey != apiKey || settings.perplexityModel != model {
            appState.savePerplexityConfig(apiKey: apiKey, model: model)
            showSavedToastTemporarily()
        }
    }
    private func showSavedToastTemporarily() {
        withAnimation { showSavedToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation { showSavedToast = false }
        }
    }
}
