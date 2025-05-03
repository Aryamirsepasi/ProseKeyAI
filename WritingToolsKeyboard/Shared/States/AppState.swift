import SwiftUI

@MainActor
class AppState: ObservableObject {
    static let shared = AppState()
    
    // Use new references to providers
    @Published var geminiProvider: GeminiProvider
    @Published var openAIProvider: OpenAIProvider
    @Published var mistralProvider: MistralProvider
    
    // Other app state
    @Published var selectedText: String = ""
    @Published var isProcessing: Bool = false
    
    // Current provider with UI binding support
    @Published private(set) var currentProvider: String
    
    var activeProvider: any AIProvider {
        switch currentProvider {
        case "openai":
            return openAIProvider
        case "gemini":
            return geminiProvider
        case "mistral":
            return mistralProvider
        default:
            return geminiProvider
        }
    }
    
    private init() {
        // Read from AppSettings
        let asettings = AppSettings.shared
        self.currentProvider = asettings.currentProvider
        
        // Initialize Gemini with custom model support
        let geminiModelEnum = asettings.geminiModel
        let geminiModelName = (geminiModelEnum == .custom)
            ? asettings.geminiCustomModel
            : geminiModelEnum.rawValue
        let geminiConfig = GeminiConfig(
            apiKey: asettings.geminiApiKey,
            modelName: geminiModelName
        )
        self.geminiProvider = GeminiProvider(config: geminiConfig)
        
        // Initialize OpenAI
        let openAIConfig = OpenAIConfig(
            apiKey: asettings.openAIApiKey,
            baseURL: asettings.openAIBaseURL,
            model: asettings.openAIModel
        )
        self.openAIProvider = OpenAIProvider(config: openAIConfig)
        
        // Initialize Mistral
        let mistralConfig = MistralConfig(
            apiKey: asettings.mistralApiKey,
            model: asettings.mistralModel
        )
        self.mistralProvider = MistralProvider(config: mistralConfig)
        
        if asettings.openAIApiKey.isEmpty && asettings.geminiApiKey.isEmpty && asettings.mistralApiKey.isEmpty {
            print("Warning: No API keys configured.")
        }
    }
    
    func saveGeminiConfig(apiKey: String, model: GeminiModel, customModelName: String? = nil) {
            AppSettings.shared.geminiApiKey = apiKey
            AppSettings.shared.geminiModel = model
            if model == .custom, let custom = customModelName {
                AppSettings.shared.geminiCustomModel = custom
            }

            let modelName = (model == .custom) ? (customModelName ?? "") : model.rawValue
            let config = GeminiConfig(apiKey: apiKey, modelName: modelName)
            geminiProvider = GeminiProvider(config: config)
        }
        
        func saveOpenAIConfig(apiKey: String, baseURL: String, model: String) {
            let asettings = AppSettings.shared
            asettings.openAIApiKey = apiKey
            asettings.openAIBaseURL = baseURL
            asettings.openAIModel = model
            
            let config = OpenAIConfig(apiKey: apiKey, baseURL: baseURL, model: model)
            openAIProvider = OpenAIProvider(config: config)
        }
        
        func setCurrentProvider(_ provider: String) {
            currentProvider = provider
            AppSettings.shared.currentProvider = provider
            objectWillChange.send()
        }
        
        func saveMistralConfig(apiKey: String, model: String) {
            let asettings = AppSettings.shared
            asettings.mistralApiKey = apiKey
            asettings.mistralModel = model
            
            let config = MistralConfig(
                apiKey: apiKey,
                model: model
            )
            mistralProvider = MistralProvider(config: config)
        }
}
