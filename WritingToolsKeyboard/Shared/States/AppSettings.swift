import Foundation
import SwiftUI

class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    private let defaults =
    UserDefaults(suiteName: "group.com.aryamirsepasi.writingtools")!
    
    @Published var geminiApiKey: String {
        didSet { defaults.set(geminiApiKey, forKey: "gemini_api_key") }
    }
    
    @Published var geminiModel: GeminiModel {
        didSet { defaults.set(geminiModel.rawValue, forKey: "gemini_model") }
    }
    
    @Published var geminiCustomModel: String {
        didSet { defaults.set(geminiCustomModel, forKey: "gemini_custom_model") }
    }
    
    @Published var openAIApiKey: String {
        didSet { defaults.set(openAIApiKey, forKey: "openai_api_key") }
    }
    
    @Published var openAIBaseURL: String {
        didSet { defaults.set(openAIBaseURL, forKey: "openai_base_url") }
    }
    
    @Published var openAIModel: String {
        didSet { defaults.set(openAIModel, forKey: "openai_model") }
    }
    
    // --- Anthropic ---
    @Published var anthropicApiKey: String {
        didSet { defaults.set(anthropicApiKey, forKey: "anthropic_api_key") }
    }
    @Published var anthropicModel: String {
        didSet { defaults.set(anthropicModel, forKey: "anthropic_model") }
    }
    
    // --- OpenRouter ---
    @Published var openRouterApiKey: String {
        didSet { defaults.set(openRouterApiKey, forKey: "openrouter_api_key") }
    }
    @Published var openRouterModel: String {
        didSet { defaults.set(openRouterModel, forKey: "openrouter_model") }
    }
    
    @Published var currentProvider: String {
        didSet { defaults.set(currentProvider, forKey: "current_provider") }
    }
    
    @Published var hasCompletedOnboarding: Bool {
        didSet { defaults.set(hasCompletedOnboarding, forKey: "has_completed_onboarding") }
    }
    
    @Published var mistralApiKey: String {
        didSet { defaults.set(mistralApiKey, forKey: "mistral_api_key") }
    }
    
    @Published var mistralModel: String {
        didSet { defaults.set(mistralModel, forKey: "mistral_model") }
    }
    
    @AppStorage("perplexity_api_key", store: UserDefaults(suiteName: "group.com.aryamirsepasi.writingtools"))
    var perplexityApiKey: String = ""
    
    @AppStorage("perplexity_model", store: UserDefaults(suiteName: "group.com.aryamirsepasi.writingtools"))
    var perplexityModel: String = PerplexityConfig.defaultModel
    
    
    // Subscription var
    @Published var isNativeAISubscribed: Bool {
        didSet { defaults.set(isNativeAISubscribed, forKey: "is_native_ai_subscribed") }
    }
    
    // Store the ID (rawValue) of the selected local LLM model type
    @Published var selectedLocalLLMId: String? {
        didSet { defaults.set(selectedLocalLLMId, forKey: "selected_local_llm_id") }
    }
    
    func reload() {
        // Re-read all values from UserDefaults
        self.geminiApiKey = self.defaults.string(forKey: "gemini_api_key") ?? ""
        let geminiModelStr = self.defaults.string(forKey: "gemini_model")
        ?? GeminiModel.twoflash.rawValue
        self.geminiModel = GeminiModel(rawValue: geminiModelStr) ?? .twoflash
        self.geminiCustomModel = self.defaults.string(forKey: "gemini_custom_model") ?? ""
        self.openAIApiKey = self.defaults.string(forKey: "openai_api_key") ?? ""
        self.openAIBaseURL = self.defaults.string(forKey: "openai_base_url")
        ?? OpenAIConfig.defaultBaseURL
        self.openAIModel = self.defaults.string(forKey: "openai_model")
        ?? OpenAIConfig.defaultModel
        self.mistralApiKey = self.defaults.string(forKey: "mistral_api_key") ?? ""
        self.mistralModel = self.defaults.string(forKey: "mistral_model")
        ?? MistralConfig.defaultModel
        self.anthropicApiKey = defaults.string(forKey: "anthropic_api_key") ?? ""
        self.anthropicModel = defaults.string(forKey: "anthropic_model")
        ?? AnthropicConfig.defaultModel
        self.openRouterApiKey = defaults.string(forKey: "openrouter_api_key") ?? ""
        self.openRouterModel = defaults.string(forKey: "openrouter_model")
        ?? OpenRouterConfig.defaultModel
        self.isNativeAISubscribed = defaults.bool(forKey: "is_native_ai_subscribed")
        self.currentProvider = self.defaults.string(forKey: "current_provider") ?? "mistral"
        self.perplexityApiKey = defaults.string(forKey: "perplexity_api_key") ?? ""
        self.perplexityModel = defaults.string(forKey: "perplexity_model") ?? PerplexityConfig.defaultModel
        
        self.hasCompletedOnboarding = self.defaults.bool(forKey: "has_completed_onboarding")
        self.selectedLocalLLMId = self.defaults.string(forKey: "selected_local_llm_id")
    }
    
    // MARK: - Init
    private init() {
        self.geminiApiKey = self.defaults.string(forKey: "gemini_api_key") ?? ""
        let geminiModelStr = self.defaults.string(forKey: "gemini_model")
        ?? GeminiModel.twoflash.rawValue
        self.geminiModel = GeminiModel(rawValue: geminiModelStr) ?? .twoflash
        
        self.geminiCustomModel = self.defaults.string(forKey: "gemini_custom_model") ?? ""
        
        self.openAIApiKey = self.defaults.string(forKey: "openai_api_key") ?? ""
        self.openAIBaseURL = self.defaults.string(forKey: "openai_base_url")
        ?? OpenAIConfig.defaultBaseURL
        self.openAIModel = self.defaults.string(forKey: "openai_model")
        ?? OpenAIConfig.defaultModel
        
        self.mistralApiKey = self.defaults.string(forKey: "mistral_api_key") ?? ""
        self.mistralModel = self.defaults.string(forKey: "mistral_model")
        ?? MistralConfig.defaultModel
        
        self.anthropicApiKey = defaults.string(forKey: "anthropic_api_key") ?? ""
        self.anthropicModel = defaults.string(forKey: "anthropic_model")
        ?? AnthropicConfig.defaultModel
        
        self.openRouterApiKey = defaults.string(forKey: "openrouter_api_key") ?? ""
        self.openRouterModel = defaults.string(forKey: "openrouter_model")
        ?? OpenRouterConfig.defaultModel
        
        self.isNativeAISubscribed = defaults.bool(forKey: "is_native_ai_subscribed")
        
        self.selectedLocalLLMId = defaults.string(forKey: "selected_local_llm_id")
        
        
        
        self.currentProvider = self.defaults.string(forKey: "current_provider") ?? "mistral"
        
        self.hasCompletedOnboarding = self.defaults.bool(forKey: "has_completed_onboarding")
    }
    
    func resetAll() {
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
        
        if (defaults.persistentDomain(forName: "group.com.aryamirsepasi.writingtools")?.keys.first)
            != nil
        {
            defaults.removePersistentDomain(forName: "group.com.aryamirsepasi.writingtools")
            defaults.synchronize()
        }
    }
}
