import Foundation
import Security

/// Manages secure storage of API keys in iOS Keychain
/// Supports App Group sharing between main app and keyboard extension
final class KeychainManager {
    static let shared = KeychainManager()

    private let accessGroup = "group.com.aryamirsepasi.writingtools"
    private let service = "com.aryamirsepasi.writingtools.apikeys"

    /// Keys for Keychain items
    enum KeychainKey: String, CaseIterable {
        case geminiApiKey = "gemini_api_key"
        case openAIApiKey = "openai_api_key"
        case anthropicApiKey = "anthropic_api_key"
        case openRouterApiKey = "openrouter_api_key"
        case perplexityApiKey = "perplexity_api_key"
        case mistralApiKey = "mistral_api_key"
    }

    private init() {}

    // MARK: - Public Interface

    /// Retrieves an API key from Keychain
    func getApiKey(_ key: KeychainKey) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecAttrAccessGroup as String: accessGroup,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }

        return string.isEmpty ? nil : string
    }

    /// Stores an API key in Keychain
    @discardableResult
    func setApiKey(_ key: KeychainKey, value: String) -> Bool {
        // Delete existing item first
        deleteApiKey(key)

        // Don't store empty values
        guard !value.isEmpty else { return true }

        guard let data = value.data(using: .utf8) else { return false }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecAttrAccessGroup as String: accessGroup,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    /// Deletes an API key from Keychain
    @discardableResult
    func deleteApiKey(_ key: KeychainKey) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecAttrAccessGroup as String: accessGroup
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    /// Deletes all API keys from Keychain
    func deleteAllApiKeys() {
        KeychainKey.allCases.forEach { deleteApiKey($0) }
    }
}
