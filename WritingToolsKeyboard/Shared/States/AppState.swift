import SwiftUI

@MainActor
class AppState: ObservableObject {
    static let shared = AppState()

    // MARK: - Lazy Provider Cache

    /// Cached provider instance - only created when accessed
    private var _cachedProvider: (any AIProvider)?

    /// Key of the currently cached provider
    private var _cachedProviderKey: String = ""

    // Other app state
    @Published var selectedText: String = ""
    @Published var isProcessing: Bool = false

    // Current provider with UI binding support
    @Published private(set) var currentProvider: String

    /// Returns the active provider, creating it lazily if needed
    var activeProvider: any AIProvider {
        let providerKey = currentProvider

        // Return cached provider if it matches current selection
        if providerKey == _cachedProviderKey, let cached = _cachedProvider {
            return cached
        }

        // Create new provider on demand
        let provider = createProvider(for: providerKey)
        _cachedProvider = provider
        _cachedProviderKey = providerKey
        return provider
    }

    private init() {
        // Only read current provider setting - no provider initialization
        let asettings = AppSettings.shared
        self.currentProvider = asettings.currentProvider
    }

    // MARK: - Lazy Provider Factory

    private func createProvider(for key: String) -> any AIProvider {
        let settings = AppSettings.shared

        switch key {
        case "openai":
            let config = OpenAIConfig(
                apiKey: settings.openAIApiKey,
                baseURL: settings.openAIBaseURL,
                model: settings.openAIModel
            )
            return OpenAIProvider(config: config)

        case "gemini":
            let modelName = (settings.geminiModel == .custom)
                ? settings.geminiCustomModel : settings.geminiModel.rawValue
            let config = GeminiConfig(
                apiKey: settings.geminiApiKey,
                modelName: modelName
            )
            return GeminiProvider(config: config)

        case "mistral":
            let config = MistralConfig(
                apiKey: settings.mistralApiKey,
                model: settings.mistralModel
            )
            return MistralProvider(config: config)

        case "anthropic":
            let config = AnthropicConfig(
                apiKey: settings.anthropicApiKey,
                model: settings.anthropicModel
            )
            return AnthropicProvider(config: config)

        case "openrouter":
            let config = OpenRouterConfig(
                apiKey: settings.openRouterApiKey,
                model: settings.openRouterModel
            )
            return OpenRouterProvider(config: config)

        case "perplexity":
            let config = PerplexityConfig(
                apiKey: settings.perplexityApiKey,
                model: settings.perplexityModel
            )
            return PerplexityProvider(config: config)

        case "foundationmodels":
            if #available(iOS 26.0, *) {
                return FoundationModelsProvider()
            }
            // Fallback to default
            fallthrough

        default:
            // Default to Gemini
            let modelName = (settings.geminiModel == .custom)
                ? settings.geminiCustomModel : settings.geminiModel.rawValue
            let config = GeminiConfig(
                apiKey: settings.geminiApiKey,
                modelName: modelName
            )
            return GeminiProvider(config: config)
        }
    }

    // MARK: - Cache Invalidation

    /// Invalidates the cached provider, forcing recreation on next access
    func invalidateProvider() {
        _cachedProvider = nil
        _cachedProviderKey = ""
    }

    // MARK: - Memory Warning Handler

    /// Cleans up provider resources to free memory
    func handleMemoryWarning() {
        // Cancel any active provider task
        _cachedProvider?.cancel()

        // Release the cached provider
        _cachedProvider = nil
        _cachedProviderKey = ""

        // Clear processing state
        isProcessing = false
        selectedText = ""
    }

    // MARK: - Provider Reload

    /// Reloads provider configuration - just invalidates cache
    func reloadProviders() {
        let settings = AppSettings.shared
        currentProvider = settings.currentProvider
        invalidateProvider()
    }

    // MARK: - Provider Selection

    func setCurrentProvider(_ provider: String) {
        // Invalidate cache when provider changes
        if provider != currentProvider {
            invalidateProvider()
        }
        currentProvider = provider
        AppSettings.shared.currentProvider = provider
    }

    // MARK: - Save Config Methods (invalidate cache if current provider)

    func saveGeminiConfig(
        apiKey: String,
        model: GeminiModel,
        customModelName: String? = nil
    ) {
        AppSettings.shared.geminiApiKey = apiKey
        AppSettings.shared.geminiModel = model
        if model == .custom, let custom = customModelName {
            AppSettings.shared.geminiCustomModel = custom
        }

        // Invalidate if this is the current provider
        if currentProvider == "gemini" {
            invalidateProvider()
        }
    }

    func saveOpenAIConfig(apiKey: String, baseURL: String, model: String) {
        let asettings = AppSettings.shared
        asettings.openAIApiKey = apiKey
        asettings.openAIBaseURL = baseURL
        asettings.openAIModel = model

        if currentProvider == "openai" {
            invalidateProvider()
        }
    }

    func saveAnthropicConfig(apiKey: String, model: String) {
        let asettings = AppSettings.shared
        asettings.anthropicApiKey = apiKey
        asettings.anthropicModel = model

        if currentProvider == "anthropic" {
            invalidateProvider()
        }
    }

    func saveOpenRouterConfig(apiKey: String, model: String) {
        let asettings = AppSettings.shared
        asettings.openRouterApiKey = apiKey
        asettings.openRouterModel = model

        if currentProvider == "openrouter" {
            invalidateProvider()
        }
    }

    func savePerplexityConfig(apiKey: String, model: String) {
        let asettings = AppSettings.shared
        asettings.perplexityApiKey = apiKey
        asettings.perplexityModel = model

        if currentProvider == "perplexity" {
            invalidateProvider()
        }
    }

    func saveMistralConfig(apiKey: String, model: String) {
        let asettings = AppSettings.shared
        asettings.mistralApiKey = apiKey
        asettings.mistralModel = model

        if currentProvider == "mistral" {
            invalidateProvider()
        }
    }
}
