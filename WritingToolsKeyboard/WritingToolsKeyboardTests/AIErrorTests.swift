import XCTest
@testable import ProseKey_AI

final class AIErrorTests: XCTestCase {

    // MARK: - shortMessage

    func testShortMessageForAllCases() {
        XCTAssertEqual(AIError.missingAPIKey.shortMessage, "No API key set")
        XCTAssertEqual(AIError.invalidAPIKey.shortMessage, "Invalid API key")
        XCTAssertEqual(AIError.serverError(statusCode: 500).shortMessage, "Server error (500)")
        XCTAssertEqual(AIError.invalidResponse.shortMessage, "Invalid response")
        XCTAssertEqual(AIError.networkError.shortMessage, "No connection")
        XCTAssertEqual(AIError.invalidSelection.shortMessage, "No text selected")
        XCTAssertEqual(AIError.modelNotLoaded.shortMessage, "Model not loaded")
        XCTAssertEqual(AIError.rateLimited.shortMessage, "Rate limit reached")
        XCTAssertEqual(AIError.unauthorized.shortMessage, "Access denied")
        XCTAssertEqual(AIError.emptyClipboard.shortMessage, "Clipboard is empty")
        XCTAssertEqual(AIError.insufficientQuota.shortMessage, "Quota exceeded")
        XCTAssertEqual(AIError.timeout.shortMessage, "Request timed out")
        XCTAssertEqual(AIError.generic("Custom").shortMessage, "Custom")
    }

    func testErrorDescriptionMatchesShortMessage() {
        let cases: [AIError] = [
            .missingAPIKey, .invalidAPIKey, .serverError(statusCode: 503),
            .invalidResponse, .networkError, .invalidSelection,
            .modelNotLoaded, .rateLimited, .unauthorized,
            .emptyClipboard, .insufficientQuota, .timeout,
            .generic("test")
        ]
        for error in cases {
            XCTAssertEqual(error.errorDescription, error.shortMessage,
                           "errorDescription should match shortMessage for \(error)")
        }
    }

    // MARK: - detailedMessage

    func testDetailedMessageIsNonEmpty() {
        let cases: [AIError] = [
            .missingAPIKey, .invalidAPIKey, .serverError(statusCode: 404),
            .invalidResponse, .networkError, .invalidSelection,
            .modelNotLoaded, .rateLimited, .unauthorized,
            .emptyClipboard, .insufficientQuota, .timeout,
            .generic("Oops")
        ]
        for error in cases {
            XCTAssertFalse(error.detailedMessage.isEmpty,
                           "detailedMessage should not be empty for \(error)")
        }
    }

    func testDetailedMessageIncludesStatusCode() {
        let error = AIError.serverError(statusCode: 502)
        XCTAssertTrue(error.detailedMessage.contains("502"))
    }

    // MARK: - icon

    func testIconForAuthErrors() {
        XCTAssertEqual(AIError.missingAPIKey.icon, "key.slash")
        XCTAssertEqual(AIError.invalidAPIKey.icon, "key.slash")
        XCTAssertEqual(AIError.unauthorized.icon, "key.slash")
    }

    func testIconForServerErrors() {
        XCTAssertEqual(AIError.serverError(statusCode: 500).icon, "exclamationmark.triangle")
        XCTAssertEqual(AIError.invalidResponse.icon, "exclamationmark.triangle")
    }

    func testIconForNetworkError() {
        XCTAssertEqual(AIError.networkError.icon, "wifi.slash")
    }

    func testIconForRateLimitAndQuota() {
        XCTAssertEqual(AIError.rateLimited.icon, "clock.badge.exclamationmark")
        XCTAssertEqual(AIError.insufficientQuota.icon, "clock.badge.exclamationmark")
    }

    func testIconForGenericError() {
        XCTAssertEqual(AIError.generic("x").icon, "exclamationmark.circle")
    }

    // MARK: - from(_:) error mapping

    func testFromNetworkNotConnectedError() {
        let nsError = NSError(domain: NSURLErrorDomain,
                              code: NSURLErrorNotConnectedToInternet)
        let mapped = AIError.from(nsError)
        XCTAssertEqual(mapped.shortMessage, AIError.networkError.shortMessage)
    }

    func testFromNetworkConnectionLostError() {
        let nsError = NSError(domain: NSURLErrorDomain,
                              code: NSURLErrorNetworkConnectionLost)
        let mapped = AIError.from(nsError)
        XCTAssertEqual(mapped.shortMessage, AIError.networkError.shortMessage)
    }

    func testFromTimeoutError() {
        let nsError = NSError(domain: NSURLErrorDomain,
                              code: NSURLErrorTimedOut)
        let mapped = AIError.from(nsError)
        XCTAssertEqual(mapped.shortMessage, AIError.timeout.shortMessage)
    }

    func testFromUnknownURLError() {
        let nsError = NSError(domain: NSURLErrorDomain,
                              code: NSURLErrorBadURL)
        let mapped = AIError.from(nsError)
        XCTAssertEqual(mapped.shortMessage, AIError.networkError.shortMessage)
    }

    func testFromAPIProvider401() {
        let domains = ["GeminiAPI", "OpenAIAPI", "MistralAPI",
                       "AnthropicAPI", "OpenRouterAPI", "PerplexityAPI",
                       "FoundationModelsAPI"]
        for domain in domains {
            let nsError = NSError(domain: domain, code: 401)
            let mapped = AIError.from(nsError)
            XCTAssertEqual(mapped.shortMessage, AIError.unauthorized.shortMessage,
                           "401 from \(domain) should map to unauthorized")
        }
    }

    func testFromAPIProvider403() {
        let nsError = NSError(domain: "OpenAIAPI", code: 403)
        let mapped = AIError.from(nsError)
        XCTAssertEqual(mapped.shortMessage, AIError.invalidAPIKey.shortMessage)
    }

    func testFromAPIProvider429() {
        let nsError = NSError(domain: "GeminiAPI", code: 429)
        let mapped = AIError.from(nsError)
        XCTAssertEqual(mapped.shortMessage, AIError.rateLimited.shortMessage)
    }

    func testFromAPIProvider402() {
        let nsError = NSError(domain: "AnthropicAPI", code: 402)
        let mapped = AIError.from(nsError)
        XCTAssertEqual(mapped.shortMessage, AIError.insufficientQuota.shortMessage)
    }

    func testFromAPIProvider500() {
        let nsError = NSError(domain: "MistralAPI", code: 500)
        let mapped = AIError.from(nsError)
        if case .serverError(let code) = mapped {
            XCTAssertEqual(code, 500)
        } else {
            XCTFail("Expected serverError, got \(mapped)")
        }
    }

    func testFromAPIKeyMissingInMessage() {
        let nsError = NSError(domain: "OpenAIAPI", code: 400,
                              userInfo: [NSLocalizedDescriptionKey: "Missing API key"])
        let mapped = AIError.from(nsError)
        XCTAssertEqual(mapped.shortMessage, AIError.missingAPIKey.shortMessage)
    }

    func testFromAPIKeyInvalidInMessage() {
        let nsError = NSError(domain: "GeminiAPI", code: 400,
                              userInfo: [NSLocalizedDescriptionKey: "Invalid api_key provided"])
        let mapped = AIError.from(nsError)
        XCTAssertEqual(mapped.shortMessage, AIError.invalidAPIKey.shortMessage)
    }

    func testFromQuotaInErrorMessage() {
        let nsError = NSError(domain: "GeminiAPI", code: 400,
                              userInfo: [NSLocalizedDescriptionKey: "Quota exceeded for this project"])
        let mapped = AIError.from(nsError)
        XCTAssertEqual(mapped.shortMessage, AIError.insufficientQuota.shortMessage)
    }

    // MARK: - Pattern matching on error description

    func testFromGenericUnauthorizedMessage() {
        let error = NSError(domain: "custom", code: 0,
                            userInfo: [NSLocalizedDescriptionKey: "unauthorized access"])
        let mapped = AIError.from(error)
        XCTAssertEqual(mapped.shortMessage, AIError.unauthorized.shortMessage)
    }

    func testFromGenericRateLimitMessage() {
        let error = NSError(domain: "custom", code: 0,
                            userInfo: [NSLocalizedDescriptionKey: "rate limit exceeded"])
        let mapped = AIError.from(error)
        XCTAssertEqual(mapped.shortMessage, AIError.rateLimited.shortMessage)
    }

    func testFromGenericBillingMessage() {
        let error = NSError(domain: "custom", code: 0,
                            userInfo: [NSLocalizedDescriptionKey: "billing issue detected"])
        let mapped = AIError.from(error)
        XCTAssertEqual(mapped.shortMessage, AIError.insufficientQuota.shortMessage)
    }

    func testFromGenericNetworkMessage() {
        let error = NSError(domain: "custom", code: 0,
                            userInfo: [NSLocalizedDescriptionKey: "network unavailable"])
        let mapped = AIError.from(error)
        XCTAssertEqual(mapped.shortMessage, AIError.networkError.shortMessage)
    }

    func testFromGenericTimeoutMessage() {
        let error = NSError(domain: "custom", code: 0,
                            userInfo: [NSLocalizedDescriptionKey: "request timed out"])
        let mapped = AIError.from(error)
        XCTAssertEqual(mapped.shortMessage, AIError.timeout.shortMessage)
    }

    func testFromGenericInvalidResponseMessage() {
        let error = NSError(domain: "custom", code: 0,
                            userInfo: [NSLocalizedDescriptionKey: "invalid response from server"])
        let mapped = AIError.from(error)
        XCTAssertEqual(mapped.shortMessage, AIError.invalidResponse.shortMessage)
    }

    func testFromUnrecognizedErrorTruncatesTo30Chars() {
        let longMessage = String(repeating: "A", count: 50)
        let error = NSError(domain: "custom", code: 0,
                            userInfo: [NSLocalizedDescriptionKey: longMessage])
        let mapped = AIError.from(error)
        if case .generic(let msg) = mapped {
            XCTAssertEqual(msg.count, 30)
        } else {
            XCTFail("Expected generic error, got \(mapped)")
        }
    }

    func testFromAIErrorPassthrough() {
        let original = AIError.emptyClipboard
        let mapped = AIError.from(original)
        // AIError conforms to Error, so from() should still return a usable mapping
        XCTAssertFalse(mapped.shortMessage.isEmpty)
    }
}
