import Foundation

enum AIError: LocalizedError {
    case missingAPIKey
    case invalidAPIKey
    case serverError(statusCode: Int)
    case invalidResponse
    case networkError
    case invalidSelection
    case modelNotLoaded
    case rateLimited
    case unauthorized
    case emptyClipboard
    case insufficientQuota
    case timeout
    case generic(String)
    
    var errorDescription: String? {
        return shortMessage
    }
    
    /// Short, concise message for keyboard display (one line)
    var shortMessage: String {
        switch self {
        case .missingAPIKey:
            return "No API key set"
        case .invalidAPIKey:
            return "Invalid API key"
        case .serverError(let code):
            return "Server error (\(code))"
        case .invalidResponse:
            return "Invalid response"
        case .networkError:
            return "No connection"
        case .invalidSelection:
            return "No text selected"
        case .modelNotLoaded:
            return "Model not loaded"
        case .rateLimited:
            return "Rate limit reached"
        case .unauthorized:
            return "Access denied"
        case .emptyClipboard:
            return "Clipboard is empty"
        case .insufficientQuota:
            return "Quota exceeded"
        case .timeout:
            return "Request timed out"
        case .generic(let message):
            return message
        }
    }
    
    /// Detailed message for settings or help
    var detailedMessage: String {
        switch self {
        case .missingAPIKey:
            return "API key is missing. Please add it in the app settings."
        case .invalidAPIKey:
            return "The provided API key is invalid. Please check your settings."
        case .serverError(let code):
            return "Server returned error \(code). Please try again later."
        case .invalidResponse:
            return "Received an invalid response from the server."
        case .networkError:
            return "Network error. Please check your connection."
        case .invalidSelection:
            return "No text selected. Please select some text first."
        case .modelNotLoaded:
            return "Model is not loaded. Please download and load the model first."
        case .rateLimited:
            return "You've exceeded the rate limit. Please wait a moment."
        case .unauthorized:
            return "Access denied. Please check your API key."
        case .emptyClipboard:
            return "Clipboard is empty. Copy some text first."
        case .insufficientQuota:
            return "API quota exceeded. Please check your account."
        case .timeout:
            return "Request timed out. Please try again."
        case .generic(let message):
            return message
        }
    }
    
    /// System icon for the error
    var icon: String {
        switch self {
        case .missingAPIKey, .invalidAPIKey, .unauthorized:
            return "key.slash"
        case .serverError, .invalidResponse:
            return "exclamationmark.triangle"
        case .networkError:
            return "wifi.slash"
        case .invalidSelection:
            return "doc.text"
        case .modelNotLoaded:
            return "arrow.down.circle"
        case .rateLimited, .insufficientQuota:
            return "clock.badge.exclamationmark"
        case .emptyClipboard:
            return "doc.on.clipboard"
        case .timeout:
            return "clock"
        case .generic:
            return "exclamationmark.circle"
        }
    }
    
    /// Maps common error patterns to AIError cases
    static func from(_ error: Error) -> AIError {
        let errorMessage = error.localizedDescription.lowercased()
        
        // Check for NSError with specific codes
        if let nsError = error as NSError? {
            // Network errors
            if nsError.domain == NSURLErrorDomain {
                switch nsError.code {
                case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost:
                    return .networkError
                case NSURLErrorTimedOut:
                    return .timeout
                default:
                    return .networkError
                }
            }
            
            // HTTP status codes
            if nsError.domain == "GeminiAPI" || nsError.domain == "OpenAIAPI" || 
               nsError.domain == "MistralAPI" || nsError.domain == "AnthropicAPI" {
                switch nsError.code {
                case 401:
                    return .unauthorized
                case 403:
                    return .invalidAPIKey
                case 429:
                    return .rateLimited
                case 402:
                    return .insufficientQuota
                case 400...499 where errorMessage.contains("quota"):
                    return .insufficientQuota
                case 500...599:
                    return .serverError(statusCode: nsError.code)
                default:
                    break
                }
                
                // Check for API key in error message
                if errorMessage.contains("api key") || errorMessage.contains("api_key") {
                    if errorMessage.contains("missing") || errorMessage.contains("empty") {
                        return .missingAPIKey
                    } else if errorMessage.contains("invalid") || errorMessage.contains("incorrect") {
                        return .invalidAPIKey
                    }
                }
            }
        }
        
        // Pattern matching on error description
        if errorMessage.contains("api key") {
            if errorMessage.contains("missing") || errorMessage.contains("empty") {
                return .missingAPIKey
            }
            return .invalidAPIKey
        }
        
        if errorMessage.contains("unauthorized") || errorMessage.contains("401") {
            return .unauthorized
        }
        
        if errorMessage.contains("rate limit") || errorMessage.contains("429") {
            return .rateLimited
        }
        
        if errorMessage.contains("quota") || errorMessage.contains("billing") {
            return .insufficientQuota
        }
        
        if errorMessage.contains("network") || errorMessage.contains("connection") {
            return .networkError
        }
        
        if errorMessage.contains("timeout") || errorMessage.contains("timed out") {
            return .timeout
        }
        
        if errorMessage.contains("invalid response") || errorMessage.contains("no text content") {
            return .invalidResponse
        }
        
        // Default to generic with original message (truncated)
        let shortDesc = String(error.localizedDescription.prefix(30))
        return .generic(shortDesc)
    }
}