import Foundation
import MLXRandom

@MainActor
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
    @Published var mistralProvider: MistralProvider
    
    var activeProvider: any AIProvider {
        if currentProvider == "openai" {
            return openAIProvider
        } else if currentProvider == "gemini" {
            return geminiProvider
        } else {
            return mistralProvider
        }
    }
    
    private init() {
        self.currentProvider = sharedDefaults.string(forKey: "current_provider") ?? "gemini"
        
        
        // Load providers
        let geminiApiKey = sharedDefaults.string(forKey: "gemini_api_key") ?? ""
        let geminiModel = sharedDefaults.string(forKey: "gemini_model") ?? "gemini-1.5-pro-latest"
        let geminiConfig = GeminiConfig(apiKey: geminiApiKey, modelName: geminiModel)
        self.geminiProvider = GeminiProvider(config: geminiConfig)
        
        let openAIApiKey = sharedDefaults.string(forKey: "openai_api_key") ?? ""
        let openAIBaseURL = sharedDefaults.string(forKey: "openai_base_url") ?? "https://api.openai.com/v1"
        let openAIOrg = sharedDefaults.string(forKey: "openai_organization")
        let openAIModel = sharedDefaults.string(forKey: "openai_model") ?? "gpt-4"
        
        let openAIConfig = OpenAIConfig(
            apiKey: openAIApiKey,
            baseURL: openAIBaseURL,
            organization: openAIOrg,
            model: openAIModel
        )
        self.openAIProvider = OpenAIProvider(config: openAIConfig)
        
        let mistralApiKey = sharedDefaults.string(forKey: "mistral_api_key") ?? ""
        let mistralBaseURL = sharedDefaults.string(forKey: "mistral_base_url") ?? "https://api.mistral.ai/v1"
        let mistralModel = sharedDefaults.string(forKey: "mistral_model") ?? "mistral-small-latest"
        
        let mistralConfig = MistralConfig(
            apiKey: mistralApiKey,
            baseURL: mistralBaseURL,
            model: mistralModel
        )
        self.mistralProvider = MistralProvider(config: mistralConfig)
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
    
    func updateMistralConfig(apiKey: String, baseURL: String, model: String) {
        sharedDefaults.set(apiKey, forKey: "mistral_api_key")
        sharedDefaults.set(baseURL, forKey: "mistral_base_url")
        sharedDefaults.set(model, forKey: "mistral_model")
        
        let config = MistralConfig(
            apiKey: apiKey,
            baseURL: baseURL,
            model: model
        )
        mistralProvider = MistralProvider(config: config)
    }
}