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
}
