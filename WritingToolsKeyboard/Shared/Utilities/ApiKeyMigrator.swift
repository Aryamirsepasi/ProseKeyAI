import Foundation

/// Handles one-time migration of API keys from UserDefaults to Keychain
final class ApiKeyMigrator {
    static let shared = ApiKeyMigrator()

    private let defaults: UserDefaults?
    private let migrationKey = "api_keys_migrated_to_keychain_v1"

    private init() {
        defaults = UserDefaults(suiteName: "group.com.aryamirsepasi.writingtools")
    }

    /// Returns true if migration has already been completed
    var hasMigrated: Bool {
        defaults?.bool(forKey: migrationKey) ?? false
    }

    /// Performs migration if not already done
    func migrateIfNeeded() {
        guard !hasMigrated else { return }
        performMigration()
    }

    private func performMigration() {
        guard let defaults = defaults else { return }

        let keychain = KeychainManager.shared

        // Mapping of UserDefaults keys to Keychain keys
        let migrations: [(udKey: String, kcKey: KeychainManager.KeychainKey)] = [
            ("gemini_api_key", .geminiApiKey),
            ("openai_api_key", .openAIApiKey),
            ("anthropic_api_key", .anthropicApiKey),
            ("openrouter_api_key", .openRouterApiKey),
            ("perplexity_api_key", .perplexityApiKey),
            ("mistral_api_key", .mistralApiKey)
        ]

        var allSucceeded = true

        for (udKey, kcKey) in migrations {
            if let value = defaults.string(forKey: udKey), !value.isEmpty {
                let success = keychain.setApiKey(kcKey, value: value)
                if success {
                    // Clear from UserDefaults after successful migration
                    defaults.removeObject(forKey: udKey)
                } else {
                    print("ApiKeyMigrator: Failed to migrate \(udKey) to Keychain")
                    allSucceeded = false
                }
            }
        }

        if allSucceeded {
            defaults.set(true, forKey: migrationKey)
            defaults.synchronize()
            print("ApiKeyMigrator: Migration completed successfully")
        }
    }

    /// For debugging/testing: resets migration state
    func resetMigration() {
        defaults?.removeObject(forKey: migrationKey)
        defaults?.synchronize()
    }
}
