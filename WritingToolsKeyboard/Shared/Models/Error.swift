import Foundation

enum AIError: LocalizedError {
    case missingAPIKey
    case serverError
    case invalidResponse
    case networkError
    case invalidSelection
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "API key is missing. Please add it in the app settings."
        case .serverError:
            return "Server returned an error. Please try again."
        case .invalidResponse:
            return "Invalid response from server."
        case .networkError:
            return "Network error. Please check your connection."
        case .invalidSelection:
            return "No text selected. Please select some text first."
        }
    }
}
