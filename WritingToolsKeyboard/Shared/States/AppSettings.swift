import Foundation
import SwiftUI

class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    private let defaults = UserDefaults(suiteName: "group.com.aryamirsepasi.writingtools")!
    
    // MARK: - Published Settings
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
    
    
    @Published var currentProvider: String {
        didSet { defaults.set(currentProvider, forKey: "current_provider") }
    }
    
    @Published var mistralApiKey: String {
        didSet { defaults.set(mistralApiKey, forKey: "mistral_api_key") }
    }
    
    
    @Published var mistralModel: String {
        didSet { defaults.set(mistralModel, forKey: "mistral_model") }
    }
    
    // MARK: - Init
    private init() {
        // Load or set defaults
        self.geminiApiKey = defaults.string(forKey: "gemini_api_key") ?? ""
        let geminiModelStr = defaults.string(forKey: "gemini_model") ?? GeminiModel.twoflash.rawValue
        self.geminiModel = GeminiModel(rawValue: geminiModelStr) ?? .twoflash
        
        self.geminiCustomModel = defaults.string(forKey: "gemini_custom_model") ?? ""
        
        self.openAIApiKey = defaults.string(forKey: "openai_api_key") ?? ""
        self.openAIBaseURL = defaults.string(forKey: "openai_base_url") ?? OpenAIConfig.defaultBaseURL
        self.openAIModel = defaults.string(forKey: "openai_model") ?? OpenAIConfig.defaultModel
        
        self.mistralApiKey = defaults.string(forKey: "mistral_api_key") ?? ""
        self.mistralModel = defaults.string(forKey: "mistral_model") ?? MistralConfig.defaultModel
        
        self.currentProvider = defaults.string(forKey: "current_provider") ?? "gemini"
    }
    
    // MARK: - Convenience
    func resetAll() {
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
    }
}
