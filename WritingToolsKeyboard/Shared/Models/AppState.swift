import Foundation

class AppState: ObservableObject {
    static let shared = AppState()
    
    private let sharedDefaults = UserDefaults(suiteName: "group.com.aryamirsepasi.writingtools")!
    
    @Published var currentProvider: String {
        didSet {
            sharedDefaults.set(currentProvider, forKey: "current_provider")
        }
    }
    
    @Published var geminiProvider: GeminiProvider
    @Published var openAIProvider: OpenAIProvider
    
    var activeProvider: any AIProvider {
        currentProvider == "openai" ? openAIProvider : geminiProvider
    }
    
    private init() {
        // Read from shared defaults
        self.currentProvider = sharedDefaults.string(forKey: "current_provider") ?? "gemini"
        
        // Load Gemini provider data
        let geminiApiKey = sharedDefaults.string(forKey: "gemini_api_key") ?? ""
        let geminiModel  = sharedDefaults.string(forKey: "gemini_model") ?? "gemini-1.5-pro-latest"
        let geminiConfig = GeminiConfig(apiKey: geminiApiKey, modelName: geminiModel)
        self.geminiProvider = GeminiProvider(config: geminiConfig)
        
        // Load OpenAI provider data
        let openAIApiKey  = sharedDefaults.string(forKey: "openai_api_key") ?? ""
        let openAIBaseURL = sharedDefaults.string(forKey: "openai_base_url") ?? "https://api.openai.com/v1"
        let openAIOrg     = sharedDefaults.string(forKey: "openai_organization")
        let openAIModel   = sharedDefaults.string(forKey: "openai_model") ?? "gpt-4"
        
        let openAIConfig = OpenAIConfig(
            apiKey: openAIApiKey,
            baseURL: openAIBaseURL,
            organization: openAIOrg,
            model: openAIModel
        )
        self.openAIProvider = OpenAIProvider(config: openAIConfig)
    }
    
    func updateGeminiConfig(apiKey: String, model: String) {
        sharedDefaults.set(apiKey, forKey: "gemini_api_key")
        sharedDefaults.set(model, forKey: "gemini_model")
        
        let config = GeminiConfig(apiKey: apiKey, modelName: model)
        geminiProvider = GeminiProvider(config: config)
    }
    
    func updateOpenAIConfig(apiKey: String, baseURL: String, organization: String?, model: String) {
        sharedDefaults.set(apiKey, forKey: "openai_api_key")
        sharedDefaults.set(baseURL, forKey: "openai_base_url")
        sharedDefaults.set(organization, forKey: "openai_organization")
        sharedDefaults.set(model, forKey: "openai_model")
        
        let config = OpenAIConfig(
            apiKey: apiKey,
            baseURL: baseURL,
            organization: organization,
            model: model
        )
        openAIProvider = OpenAIProvider(config: config)
    }
}
