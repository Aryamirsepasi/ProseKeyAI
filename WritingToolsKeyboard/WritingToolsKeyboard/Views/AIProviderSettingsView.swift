import SwiftUI

struct GeminiSettingsView: View {
    @ObservedObject var appState: AppState
    
    @AppStorage("gemini_api_key", store: UserDefaults(suiteName: "group.com.aryamirsepasi.writingtools"))
    private var apiKey = ""
    
    @AppStorage("gemini_model", store: UserDefaults(suiteName: "group.com.aryamirsepasi.writingtools"))
    private var modelName = "gemini-2.0-flash-exp"
    
    private let models = [
        ("gemini-2.0-flash-lite-preview-02-05", "Gemini 2.0 Flash Lite"),
        ("gemini-2.0-flash-exp", "Gemini 2.0 Flash"),
        ("gemini-2.0-pro-exp-02-05", "Gemini 2.0 Pro"),
        ("gemini-2.0-flash-thinking-exp-01-21", "Gemini 2.0 Flash Thinking"),
        
    ]
    
    var body: some View {
        Group {
            TextField("API Key", text: $apiKey)
                .autocapitalization(.none)
                .disableAutocorrection(true)
            
            Picker("Model", selection: $modelName) {
                ForEach(models, id: \.0) { model in
                    Text(model.1).tag(model.0)
                }
            }
            
            Button("Get API Key") {
                if let url = URL(string: "https://makersuite.google.com/app/apikey") {
                    UIApplication.shared.open(url)
                }
            }
        }
        .onChange(of: apiKey) { _, newValue in
            appState.updateGeminiConfig(apiKey: newValue, model: modelName)
        }
        .onChange(of: modelName) { _, newValue in
            appState.updateGeminiConfig(apiKey: apiKey, model: newValue)
        }
    }
}


struct OpenAISettingsView: View {
    @ObservedObject var appState: AppState
    
    @AppStorage("openai_api_key", store: UserDefaults(suiteName: "group.com.aryamirsepasi.writingtools"))
    private var apiKey = ""
    
    @AppStorage("openai_base_url", store: UserDefaults(suiteName: "group.com.aryamirsepasi.writingtools"))
    private var baseURL = "https://api.openai.com/v1"
    
    @AppStorage("openai_organization", store: UserDefaults(suiteName: "group.com.aryamirsepasi.writingtools"))
    private var organization = ""
    
    @AppStorage("openai_model", store: UserDefaults(suiteName: "group.com.aryamirsepasi.writingtools"))
    private var model = "gpt-4o"
    
    private let models = [
        "gpt-4o": "GPT-4o (Optimized)",
        "gpt-4o-mini": "GPT-4o Mini (Lightweight)",
        "gpt-4": "GPT-4 (Most Capable)",
        "gpt-3.5-turbo": "GPT-3.5 Turbo (Faster)"
    ]
    
    var body: some View {
        Group {
            // Show as plain text
            TextField("API Key", text: $apiKey)
                .autocapitalization(.none)
                .disableAutocorrection(true)
            
            TextField("Base URL", text: $baseURL)
                .autocapitalization(.none)
            
            TextField("Organization ID (Optional)", text: $organization)
                .autocapitalization(.none)
            
            Picker("Model", selection: $model) {
                ForEach(Array(models.keys.sorted()), id: \.self) { key in
                    Text(models[key] ?? key).tag(key)
                }
            }
            
            Button("Get API Key") {
                if let url = URL(string: "https://platform.openai.com/account/api-keys") {
                    UIApplication.shared.open(url)
                }
            }
        }
        .onChange(of: apiKey) { _, _ in
            updateConfig()
        }
        .onChange(of: baseURL) { _, _ in
            updateConfig()
        }
        .onChange(of: organization) { _, _ in
            updateConfig()
        }
        .onChange(of: model) { _, _ in
            updateConfig()
        }
    }
    
    private func updateConfig() {
        appState.updateOpenAIConfig(
            apiKey: apiKey,
            baseURL: baseURL,
            organization: organization,
            model: model
        )
    }
}

struct MistralSettingsView: View {
    @ObservedObject var appState: AppState
    
    @AppStorage("mistral_api_key", store: UserDefaults(suiteName: "group.com.aryamirsepasi.writingtools"))
    private var apiKey = ""
    
    @AppStorage("mistral_base_url", store: UserDefaults(suiteName: "group.com.aryamirsepasi.writingtools"))
    private var baseURL = "https://api.mistral.ai/v1"
    
    @AppStorage("mistral_model", store: UserDefaults(suiteName: "group.com.aryamirsepasi.writingtools"))
    private var model = "mistral-small-latest"
    
    private let models = [
        "mistral-small-latest": "Mistral Small (Fast)",
        "mistral-medium-latest": "Mistral Medium (Balanced)",
        "mistral-large-latest": "Mistral Large (Most Capable)",
    ]
    
    var body: some View {
        Group {
            // Show as plain text
            TextField("API Key", text: $apiKey)
                .autocapitalization(.none)
                .disableAutocorrection(true)
            
            TextField("Base URL", text: $baseURL)
                .autocapitalization(.none)
            
            
            Picker("Model", selection: $model) {
                ForEach(Array(models.keys.sorted()), id: \.self) { key in
                    Text(models[key] ?? key).tag(key)
                }
            }
            
            Button("Get API Key") {
                if let url = URL(string: "https://console.mistral.ai/api-keys/") {
                    UIApplication.shared.open(url)
                }
            }
        }
        .onChange(of: apiKey) { _, _ in
            updateConfig()
        }
        .onChange(of: baseURL) { _, _ in
            updateConfig()
        }
        
        .onChange(of: model) { _, _ in
            updateConfig()
        }
    }
    
    private func updateConfig() {
        appState.updateMistralConfig(
            apiKey: apiKey,
            baseURL: baseURL,
            model: model
        )
    }
}
