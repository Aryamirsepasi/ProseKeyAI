import XCTest
@testable import ProseKey_AI

@MainActor
final class AppStateTests: XCTestCase {
    private let suiteName = "group.com.aryamirsepasi.writingtools"

    override func setUp() {
        super.setUp()
        // Reset to a known state
        AppState.shared.invalidateProvider()
        AppState.shared.isProcessing = false
        AppState.shared.selectedText = ""
    }

    // MARK: - Provider Caching

    func testActiveProviderReturnsSameInstanceOnRepeatedAccess() {
        let first = AppState.shared.activeProvider
        let second = AppState.shared.activeProvider
        // Both should be the same object instance (cached)
        XCTAssertTrue(first === second)
    }

    func testInvalidateProviderClearsCache() {
        let first = AppState.shared.activeProvider
        AppState.shared.invalidateProvider()
        let second = AppState.shared.activeProvider
        // After invalidation a new instance should be created
        XCTAssertFalse(first === second)
    }

    // MARK: - setCurrentProvider

    func testSetCurrentProviderUpdatesValue() {
        AppState.shared.setCurrentProvider("openai")
        XCTAssertEqual(AppState.shared.currentProvider, "openai")
    }

    func testSetCurrentProviderInvalidatesCacheWhenChanged() {
        AppState.shared.setCurrentProvider("gemini")
        let first = AppState.shared.activeProvider
        AppState.shared.setCurrentProvider("openai")
        let second = AppState.shared.activeProvider
        XCTAssertFalse(first === second)
    }

    func testSetSameProviderDoesNotInvalidateCache() {
        AppState.shared.setCurrentProvider("gemini")
        let first = AppState.shared.activeProvider
        AppState.shared.setCurrentProvider("gemini")
        let second = AppState.shared.activeProvider
        XCTAssertTrue(first === second)
    }

    // MARK: - handleMemoryWarning

    func testHandleMemoryWarningClearsState() {
        AppState.shared.isProcessing = true
        AppState.shared.selectedText = "Some text"
        _ = AppState.shared.activeProvider // Force cache

        AppState.shared.handleMemoryWarning()

        XCTAssertFalse(AppState.shared.isProcessing)
        XCTAssertTrue(AppState.shared.selectedText.isEmpty)
    }

    func testHandleMemoryWarningInvalidatesProvider() {
        let first = AppState.shared.activeProvider
        AppState.shared.handleMemoryWarning()
        let second = AppState.shared.activeProvider
        XCTAssertFalse(first === second)
    }

    // MARK: - reloadProviders

    func testReloadProvidersInvalidatesCache() {
        let first = AppState.shared.activeProvider
        AppState.shared.reloadProviders()
        let second = AppState.shared.activeProvider
        XCTAssertFalse(first === second)
    }

    // MARK: - Provider Factory

    func testDefaultProviderCreatesGeminiProvider() {
        AppState.shared.setCurrentProvider("unknown_provider")
        let provider = AppState.shared.activeProvider
        XCTAssertTrue(type(of: provider) == GeminiProvider.self)
    }

    func testOpenAIProviderCreation() {
        AppState.shared.setCurrentProvider("openai")
        let provider = AppState.shared.activeProvider
        XCTAssertTrue(type(of: provider) == OpenAIProvider.self)
    }

    func testGeminiProviderCreation() {
        AppState.shared.setCurrentProvider("gemini")
        let provider = AppState.shared.activeProvider
        XCTAssertTrue(type(of: provider) == GeminiProvider.self)
    }

    func testMistralProviderCreation() {
        AppState.shared.setCurrentProvider("mistral")
        let provider = AppState.shared.activeProvider
        XCTAssertTrue(type(of: provider) == MistralProvider.self)
    }

    func testAnthropicProviderCreation() {
        AppState.shared.setCurrentProvider("anthropic")
        let provider = AppState.shared.activeProvider
        XCTAssertTrue(type(of: provider) == AnthropicProvider.self)
    }

    func testOpenRouterProviderCreation() {
        AppState.shared.setCurrentProvider("openrouter")
        let provider = AppState.shared.activeProvider
        XCTAssertTrue(type(of: provider) == OpenRouterProvider.self)
    }

    func testPerplexityProviderCreation() {
        AppState.shared.setCurrentProvider("perplexity")
        let provider = AppState.shared.activeProvider
        XCTAssertTrue(type(of: provider) == PerplexityProvider.self)
    }
}
