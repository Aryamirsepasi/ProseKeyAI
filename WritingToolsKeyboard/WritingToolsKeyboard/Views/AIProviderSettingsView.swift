import SwiftUI

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
        Section {
            SecureField("API Key", text: $apiKey)
                .autocapitalization(.none)
                .autocorrectionDisabled()
            
            Picker("Model", selection: $modelSelection) {
                ForEach(GeminiModel.allCases, id: \.self) { model in
                    Text(model.displayName).tag(model)
                }
            }
            
            if modelSelection == .custom {
                TextField("Custom Model Name", text: $customModel)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
            }
            
            Button("Save Changes") {
                appState.saveGeminiConfig(apiKey: apiKey, model: modelSelection, customModelName: customModel)
            }
            .disabled(apiKey.isEmpty || (modelSelection == .custom && customModel.isEmpty))
        }
    }
}


struct OpenAISettingsView: View {
    @ObservedObject var appState: AppState
    @State private var apiKey: String
    @State private var baseURL: String
    @State private var modelSelection: String
    
    init(appState: AppState) {
        self.appState = appState
        let settings = AppSettings.shared
        _apiKey = State(initialValue: settings.openAIApiKey)
        _baseURL = State(initialValue: settings.openAIBaseURL)
        _modelSelection = State(initialValue: settings.openAIModel)
    }
    
    var body: some View {
        Section {
            SecureField("API Key", text: $apiKey)
                .autocapitalization(.none)
                .autocorrectionDisabled()
            
            TextField("Base URL", text: $baseURL)
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .disableAutocorrection(true)
            
            Picker("Model", selection: $modelSelection) {
                ForEach(OpenAIModel.allCases, id: \.self) { model in
                    Text(model.displayName).tag(model.rawValue)
                }
                Text("Custom").tag("custom")
            }
            
            if modelSelection == "custom" {
                TextField("Custom Model", text: $modelSelection)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
            }
            
            
            Button("Save Changes") {
                appState.saveOpenAIConfig(
                    apiKey: apiKey,
                    baseURL: baseURL,
                    model: modelSelection
                )
            }
            .disabled(apiKey.isEmpty || baseURL.isEmpty || modelSelection.isEmpty)
        }
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
        Section {
            SecureField("API Key", text: $apiKey)
                .autocapitalization(.none)
                .autocorrectionDisabled()
            
            Picker("Model", selection: $modelSelection) {
                ForEach(MistralModel.allCases, id: \.self) { model in
                    Text(model.displayName).tag(model.rawValue)
                }
                Text("Custom").tag("custom")
            }
            
            if modelSelection == "custom" {
                TextField("Custom Model", text: $modelSelection)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
            }
            
            Button("Save Changes") {
                appState.saveMistralConfig(
                    apiKey: apiKey,
                    model: modelSelection
                )
            }
            .disabled(apiKey.isEmpty || modelSelection.isEmpty)
        }
    }
}
