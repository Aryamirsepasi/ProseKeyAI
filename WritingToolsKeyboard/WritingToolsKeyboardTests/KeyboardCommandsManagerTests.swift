import XCTest
@testable import WritingToolsKeyboard

@MainActor
final class KeyboardCommandsManagerTests: XCTestCase {
    private let suiteName = "group.com.aryamirsepasi.writingtools"

    override func setUp() {
        super.setUp()
        UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
    }

    func testAddUpdateDeleteCommand() {
        let manager = KeyboardCommandsManager()
        let initialCount = manager.commands.count

        let command = KeyboardCommand(name: "Test", prompt: "Prompt", icon: "star")
        manager.addCommand(command)
        XCTAssertTrue(manager.commands.contains(where: { $0.id == command.id }))

        var updated = command
        updated.prompt = "Updated"
        manager.updateCommand(updated)
        XCTAssertEqual(manager.commands.first(where: { $0.id == command.id })?.prompt, "Updated")

        manager.deleteCommand(updated)
        XCTAssertFalse(manager.commands.contains(where: { $0.id == command.id }))
        XCTAssertEqual(manager.commands.count, initialCount)
    }

    func testReloadCommandsOnNotification() async {
        let manager = KeyboardCommandsManager()
        let command = KeyboardCommand(name: "Reload Test", prompt: "Prompt", icon: "star")

        let defaults = UserDefaults(suiteName: suiteName)
        let data = try? JSONEncoder().encode([command])
        defaults?.set(data, forKey: "keyboard_commands_list")

        postKeyboardCommandsDidChange()
        try? await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertTrue(manager.commands.contains(where: { $0.id == command.id }))
    }

    func testBuiltInMigrationAddsNameKey() {
        let defaults = UserDefaults(suiteName: suiteName)
        let legacy = KeyboardCommand(
            id: UUID(),
            name: "Proofread",
            prompt: "",
            icon: "magnifyingglass",
            isBuiltIn: true,
            nameKey: nil
        )
        let data = try? JSONEncoder().encode([legacy])
        defaults?.set(data, forKey: "keyboard_commands_list")
        defaults?.set(true, forKey: "built_in_commands_shown")
        defaults?.set(1, forKey: "built_in_commands_version")

        let manager = KeyboardCommandsManager()
        let migrated = manager.commands.first(where: { $0.name == "Proofread" })
        XCTAssertEqual(migrated?.nameKey, "Proofread")
    }

    func testBuiltInPromptMigrationUpdatesUnmodifiedPrompt() {
        let defaults = UserDefaults(suiteName: suiteName)
        let v3Prompt = KeyboardCommandsManager.builtInPrompt(nameKey: "Proofread", version: 3)
        let v4Prompt = KeyboardCommandsManager.builtInPrompt(nameKey: "Proofread", version: 4)
        XCTAssertNotNil(v3Prompt)
        XCTAssertNotNil(v4Prompt)

        let legacy = KeyboardCommand(
            id: UUID(),
            name: "Proofread",
            prompt: v3Prompt ?? "",
            icon: "magnifyingglass",
            isBuiltIn: true,
            nameKey: "Proofread"
        )
        let data = try? JSONEncoder().encode([legacy])
        defaults?.set(data, forKey: "keyboard_commands_list")
        defaults?.set(true, forKey: "built_in_commands_shown")
        defaults?.set(3, forKey: "built_in_commands_version")

        let manager = KeyboardCommandsManager()
        let migrated = manager.commands.first(where: { $0.name == "Proofread" })
        XCTAssertEqual(migrated?.prompt, v4Prompt)
    }

    func testBuiltInPromptMigrationPreservesEditedPrompt() {
        let defaults = UserDefaults(suiteName: suiteName)
        let v3Prompt = KeyboardCommandsManager.builtInPrompt(nameKey: "Proofread", version: 3) ?? ""
        let editedPrompt = v3Prompt.replacingOccurrences(of: "proofreading assistant", with: "proofreading helper")
        XCTAssertNotEqual(editedPrompt, v3Prompt)

        let legacy = KeyboardCommand(
            id: UUID(),
            name: "Proofread",
            prompt: editedPrompt,
            icon: "magnifyingglass",
            isBuiltIn: true,
            nameKey: "Proofread"
        )
        let data = try? JSONEncoder().encode([legacy])
        defaults?.set(data, forKey: "keyboard_commands_list")
        defaults?.set(true, forKey: "built_in_commands_shown")
        defaults?.set(3, forKey: "built_in_commands_version")

        let manager = KeyboardCommandsManager()
        let migrated = manager.commands.first(where: { $0.name == "Proofread" })
        XCTAssertEqual(migrated?.prompt, editedPrompt)
    }

    func testFreshInstallUsesV4Prompts() {
        let manager = KeyboardCommandsManager()
        let prompt = manager.commands.first(where: { $0.name == "Proofread" })?.prompt
        let expected = KeyboardCommandsManager.builtInPrompt(nameKey: "Proofread", version: 4)
        XCTAssertEqual(prompt, expected)
    }

    func testResetBuiltInPromptsRestoresDefaults() {
        let manager = KeyboardCommandsManager()
        guard let command = manager.commands.first(where: { $0.name == "Proofread" }) else {
            XCTFail("Missing built-in command")
            return
        }
        
        var edited = command
        edited.prompt = "Custom prompt"
        manager.updateCommand(edited)
        
        manager.resetBuiltInPromptsToDefaults()
        
        let updated = manager.commands.first(where: { $0.id == command.id })
        let expected = KeyboardCommandsManager.builtInPrompt(nameKey: "Proofread", version: 4)
        XCTAssertEqual(updated?.prompt, expected)
        XCTAssertEqual(updated?.name, command.name)
        XCTAssertEqual(updated?.icon, command.icon)
    }

    func testDeleteAllCustomCommandsRemovesCustomOnly() {
        let manager = KeyboardCommandsManager()
        let custom = KeyboardCommand(name: "Custom", prompt: "Prompt", icon: "star")
        manager.addCommand(custom)
        XCTAssertTrue(manager.customCommands.contains(where: { $0.id == custom.id }))
        
        manager.deleteAllCustomCommands()
        
        XCTAssertFalse(manager.customCommands.contains(where: { $0.id == custom.id }))
        XCTAssertFalse(manager.builtInCommands.isEmpty)
    }
}
