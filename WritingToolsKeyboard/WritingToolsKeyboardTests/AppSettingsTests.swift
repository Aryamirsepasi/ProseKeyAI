import XCTest
@testable import ProseKey_AI

@MainActor
final class AppSettingsTests: XCTestCase {
    private let suiteName = "group.com.aryamirsepasi.writingtools"

    override func setUp() {
        super.setUp()
        // Reset version tracking to a known state
        let defaults = UserDefaults(suiteName: suiteName)
        defaults?.removeObject(forKey: "settings_version")
        AppSettings.shared.reload()
    }

    // MARK: - Version Tracking

    func testHasChangesReturnsFalseAfterReload() {
        AppSettings.shared.reload()
        XCTAssertFalse(AppSettings.shared.hasChanges())
    }

    func testHasChangesReturnsTrueAfterExternalBump() {
        let defaults = UserDefaults(suiteName: suiteName)!
        let current = defaults.integer(forKey: "settings_version")
        defaults.set(current + 1, forKey: "settings_version")
        XCTAssertTrue(AppSettings.shared.hasChanges())
    }

    func testReloadIfNeededReturnsFalseWhenNoChanges() {
        AppSettings.shared.reload()
        XCTAssertFalse(AppSettings.shared.reloadIfNeeded())
    }

    func testReloadIfNeededReturnsTrueWhenChanged() {
        let defaults = UserDefaults(suiteName: suiteName)!
        let current = defaults.integer(forKey: "settings_version")
        defaults.set(current + 1, forKey: "settings_version")
        XCTAssertTrue(AppSettings.shared.reloadIfNeeded())
    }

    func testReloadIfNeededClearsChangedState() {
        let defaults = UserDefaults(suiteName: suiteName)!
        let current = defaults.integer(forKey: "settings_version")
        defaults.set(current + 1, forKey: "settings_version")
        AppSettings.shared.reloadIfNeeded()
        XCTAssertFalse(AppSettings.shared.hasChanges())
    }

    // MARK: - Property Changes Bump Version

    func testChangingCurrentProviderBumpsVersion() {
        let defaults = UserDefaults(suiteName: suiteName)!
        AppSettings.shared.reload()
        let before = defaults.integer(forKey: "settings_version")
        AppSettings.shared.currentProvider = "openai"
        let after = defaults.integer(forKey: "settings_version")
        XCTAssertGreaterThan(after, before)
    }

    func testChangingOnboardingBumpsVersion() {
        let defaults = UserDefaults(suiteName: suiteName)!
        AppSettings.shared.reload()
        let before = defaults.integer(forKey: "settings_version")
        AppSettings.shared.hasCompletedOnboarding = true
        let after = defaults.integer(forKey: "settings_version")
        XCTAssertGreaterThan(after, before)
    }

    // MARK: - Reload restores values

    func testReloadRestoresCurrentProvider() {
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.set("anthropic", forKey: "current_provider")
        // Bump version so reloadIfNeeded will reload
        let current = defaults.integer(forKey: "settings_version")
        defaults.set(current + 1, forKey: "settings_version")
        AppSettings.shared.reloadIfNeeded()
        XCTAssertEqual(AppSettings.shared.currentProvider, "anthropic")
    }

    func testReloadDefaultProviderIsMistral() {
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removeObject(forKey: "current_provider")
        let current = defaults.integer(forKey: "settings_version")
        defaults.set(current + 1, forKey: "settings_version")
        AppSettings.shared.reloadIfNeeded()
        XCTAssertEqual(AppSettings.shared.currentProvider, "mistral")
    }
}
