import SwiftUI

struct GeminiSettingsView: View {
    @ObservedObject var appState: AppState
    
    @AppStorage("gemini_api_key", store: UserDefaults(suiteName: "group.com.aryamirsepasi.writingtools"))
    private var apiKey = ""
    
    @AppStorage("gemini_model", store: UserDefaults(suiteName: "group.com.aryamirsepasi.writingtools"))
    private var modelName = "gemini-1.5-pro-latest"
    
    private let models = [
        ("gemini-1.5-pro-latest", "Gemini 1.5 Pro (Most Capable)"),
        ("gemini-1.5-flash-latest", "Gemini 1.5 Flash (Fast)"),
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
    private var model = "gpt-4"
    
    private let models = [
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
