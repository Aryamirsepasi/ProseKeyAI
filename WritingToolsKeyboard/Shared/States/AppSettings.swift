import Foundation
import SwiftUI

@MainActor
class AppSettings: ObservableObject {
    static let shared = AppSettings()

    private let defaults: UserDefaults

    // MARK: - Settings Version Tracking

    private static let settingsVersionKey = "settings_version"
    private var lastLoadedVersion: Int = 0
    private var suppressVersionBump = false

    private func bumpVersion() {
        guard !suppressVersionBump else { return }
        let current = defaults.integer(forKey: Self.settingsVersionKey)
        defaults.set(current + 1, forKey: Self.settingsVersionKey)
    }

    /// Returns true if settings have changed since last reload
    func hasChanges() -> Bool {
        return defaults.integer(forKey: Self.settingsVersionKey) != lastLoadedVersion
    }

    /// Only reloads if settings have changed. Returns true if reload occurred.
    @discardableResult
    func reloadIfNeeded() -> Bool {
        guard hasChanges() else { return false }
        reload()
        return true
    }

    private static func getSharedDefaults() -> UserDefaults {
        guard let defaults = UserDefaults(suiteName: "group.com.aryamirsepasi.writingtools") else {
            #if DEBUG
            assertionFailure("Failed to create UserDefaults with app group. Falling back to standard defaults.")
            #endif
            return UserDefaults.standard
        }
        return defaults
    }

    // MARK: - API Keys (Keychain-backed)

    // Cache for API keys to support @Published behavior
    @Published private var _geminiApiKeyCache: String = ""
    var geminiApiKey: String {
        get {
            // Try Keychain first, fallback to UserDefaults only before migration completes
            if let keychainValue = KeychainManager.shared.getApiKey(.geminiApiKey) {
                return keychainValue
            }
            guard !ApiKeyMigrator.shared.hasMigrated else { return "" }
            return defaults.string(forKey: "gemini_api_key") ?? ""
        }
        set {
            KeychainManager.shared.setApiKey(.geminiApiKey, value: newValue)
            _geminiApiKeyCache = newValue
            bumpVersion()
        }
    }

    @Published private var _openAIApiKeyCache: String = ""
    var openAIApiKey: String {
        get {
            if let keychainValue = KeychainManager.shared.getApiKey(.openAIApiKey) {
                return keychainValue
            }
            guard !ApiKeyMigrator.shared.hasMigrated else { return "" }
            return defaults.string(forKey: "openai_api_key") ?? ""
        }
        set {
            KeychainManager.shared.setApiKey(.openAIApiKey, value: newValue)
            _openAIApiKeyCache = newValue
            bumpVersion()
        }
    }

    @Published private var _anthropicApiKeyCache: String = ""
    var anthropicApiKey: String {
        get {
            if let keychainValue = KeychainManager.shared.getApiKey(.anthropicApiKey) {
                return keychainValue
            }
            guard !ApiKeyMigrator.shared.hasMigrated else { return "" }
            return defaults.string(forKey: "anthropic_api_key") ?? ""
        }
        set {
            KeychainManager.shared.setApiKey(.anthropicApiKey, value: newValue)
            _anthropicApiKeyCache = newValue
            bumpVersion()
        }
    }

    @Published private var _openRouterApiKeyCache: String = ""
    var openRouterApiKey: String {
        get {
            if let keychainValue = KeychainManager.shared.getApiKey(.openRouterApiKey) {
                return keychainValue
            }
            guard !ApiKeyMigrator.shared.hasMigrated else { return "" }
            return defaults.string(forKey: "openrouter_api_key") ?? ""
        }
        set {
            KeychainManager.shared.setApiKey(.openRouterApiKey, value: newValue)
            _openRouterApiKeyCache = newValue
            bumpVersion()
        }
    }

    @Published private var _perplexityApiKeyCache: String = ""
    var perplexityApiKey: String {
        get {
            if let keychainValue = KeychainManager.shared.getApiKey(.perplexityApiKey) {
                return keychainValue
            }
            guard !ApiKeyMigrator.shared.hasMigrated else { return "" }
            return defaults.string(forKey: "perplexity_api_key") ?? ""
        }
        set {
            KeychainManager.shared.setApiKey(.perplexityApiKey, value: newValue)
            _perplexityApiKeyCache = newValue
            bumpVersion()
        }
    }

    @Published private var _mistralApiKeyCache: String = ""
    var mistralApiKey: String {
        get {
            if let keychainValue = KeychainManager.shared.getApiKey(.mistralApiKey) {
                return keychainValue
            }
            guard !ApiKeyMigrator.shared.hasMigrated else { return "" }
            return defaults.string(forKey: "mistral_api_key") ?? ""
        }
        set {
            KeychainManager.shared.setApiKey(.mistralApiKey, value: newValue)
            _mistralApiKeyCache = newValue
            bumpVersion()
        }
    }

    // MARK: - Non-Sensitive Settings (UserDefaults-backed)

    @Published var geminiModel: GeminiModel {
        didSet {
            defaults.set(geminiModel.rawValue, forKey: "gemini_model")
            bumpVersion()
        }
    }

    @Published var geminiCustomModel: String {
        didSet {
            defaults.set(geminiCustomModel, forKey: "gemini_custom_model")
            bumpVersion()
        }
    }

    @Published var openAIBaseURL: String {
        didSet {
            defaults.set(openAIBaseURL, forKey: "openai_base_url")
            bumpVersion()
        }
    }

    @Published var openAIModel: String {
        didSet {
            defaults.set(openAIModel, forKey: "openai_model")
            bumpVersion()
        }
    }

    @Published var anthropicModel: String {
        didSet {
            defaults.set(anthropicModel, forKey: "anthropic_model")
            bumpVersion()
        }
    }

    @Published var openRouterModel: String {
        didSet {
            defaults.set(openRouterModel, forKey: "openrouter_model")
            bumpVersion()
        }
    }

    @Published var perplexityModel: String {
        didSet {
            defaults.set(perplexityModel, forKey: "perplexity_model")
            bumpVersion()
        }
    }

    @Published var mistralModel: String {
        didSet {
            defaults.set(mistralModel, forKey: "mistral_model")
            bumpVersion()
        }
    }

    @Published var currentProvider: String {
        didSet {
            defaults.set(currentProvider, forKey: "current_provider")
            bumpVersion()
        }
    }

    @Published var hasCompletedOnboarding: Bool {
        didSet {
            defaults.set(hasCompletedOnboarding, forKey: "has_completed_onboarding")
            bumpVersion()
        }
    }

    @Published var isNativeAISubscribed: Bool {
        didSet {
            defaults.set(isNativeAISubscribed, forKey: "is_native_ai_subscribed")
            bumpVersion()
        }
    }

    @Published var useFoundationModels: Bool {
        didSet {
            defaults.set(useFoundationModels, forKey: "use_foundation_models")
            bumpVersion()
        }
    }

    // MARK: - Reload

    func reload() {
        // Update version tracking
        lastLoadedVersion = defaults.integer(forKey: Self.settingsVersionKey)
        suppressVersionBump = true
        defer { suppressVersionBump = false }

        // API keys are computed properties - notify observers
        objectWillChange.send()

        // Reload non-API-key properties
        let geminiModelStr = self.defaults.string(forKey: "gemini_model")
            ?? GeminiModel.flash.rawValue
        self.geminiModel = GeminiModel(rawValue: geminiModelStr) ?? .flash
        self.geminiCustomModel = self.defaults.string(forKey: "gemini_custom_model") ?? ""

        self.openAIBaseURL = self.defaults.string(forKey: "openai_base_url")
            ?? OpenAIConfig.defaultBaseURL
        self.openAIModel = self.defaults.string(forKey: "openai_model")
            ?? OpenAIConfig.defaultModel

        self.mistralModel = self.defaults.string(forKey: "mistral_model")
            ?? MistralConfig.defaultModel

        self.anthropicModel = defaults.string(forKey: "anthropic_model")
            ?? AnthropicConfig.defaultModel

        self.openRouterModel = defaults.string(forKey: "openrouter_model")
            ?? OpenRouterConfig.defaultModel

        self.perplexityModel = defaults.string(forKey: "perplexity_model")
            ?? PerplexityConfig.defaultModel

        self.isNativeAISubscribed = defaults.bool(forKey: "is_native_ai_subscribed")
        self.useFoundationModels = defaults.bool(forKey: "use_foundation_models")
        self.currentProvider = self.defaults.string(forKey: "current_provider") ?? "mistral"
        self.hasCompletedOnboarding = self.defaults.bool(forKey: "has_completed_onboarding")
    }

    // MARK: - Init

    private init() {
        self.defaults = Self.getSharedDefaults()

        // Run migration from UserDefaults to Keychain
        ApiKeyMigrator.shared.migrateIfNeeded()

        // Initialize version tracking
        self.lastLoadedVersion = defaults.integer(forKey: Self.settingsVersionKey)

        // Load non-API-key properties from UserDefaults
        let geminiModelStr = self.defaults.string(forKey: "gemini_model")
            ?? GeminiModel.flash.rawValue
        self.geminiModel = GeminiModel(rawValue: geminiModelStr) ?? .flash
        self.geminiCustomModel = self.defaults.string(forKey: "gemini_custom_model") ?? ""

        self.openAIBaseURL = self.defaults.string(forKey: "openai_base_url")
            ?? OpenAIConfig.defaultBaseURL
        self.openAIModel = self.defaults.string(forKey: "openai_model")
            ?? OpenAIConfig.defaultModel

        self.mistralModel = self.defaults.string(forKey: "mistral_model")
            ?? MistralConfig.defaultModel

        self.anthropicModel = defaults.string(forKey: "anthropic_model")
            ?? AnthropicConfig.defaultModel

        self.openRouterModel = defaults.string(forKey: "openrouter_model")
            ?? OpenRouterConfig.defaultModel

        self.perplexityModel = defaults.string(forKey: "perplexity_model")
            ?? PerplexityConfig.defaultModel

        self.isNativeAISubscribed = defaults.bool(forKey: "is_native_ai_subscribed")
        self.useFoundationModels = defaults.bool(forKey: "use_foundation_models")

        self.currentProvider = self.defaults.string(forKey: "current_provider") ?? "mistral"
        self.hasCompletedOnboarding = self.defaults.bool(forKey: "has_completed_onboarding")
    }

    // MARK: - Reset

    func resetAll() {
        // Clear Keychain API keys
        KeychainManager.shared.deleteAllApiKeys()

        // Clear UserDefaults
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)

        if (defaults.persistentDomain(forName: "group.com.aryamirsepasi.writingtools")?.keys.first)
            != nil
        {
            defaults.removePersistentDomain(forName: "group.com.aryamirsepasi.writingtools")
        }

        // Reset migration flag so it can run again
        ApiKeyMigrator.shared.resetMigration()
    }
}
