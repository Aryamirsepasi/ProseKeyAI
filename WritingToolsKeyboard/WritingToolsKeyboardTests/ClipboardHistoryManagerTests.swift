import XCTest
@testable import WritingToolsKeyboardExt

@MainActor
final class ClipboardHistoryManagerTests: XCTestCase {
    private let suiteName = "group.com.aryamirsepasi.writingtools"

    override func setUp() {
        super.setUp()
        let defaults = UserDefaults(suiteName: suiteName)
        defaults?.removePersistentDomain(forName: suiteName)
        defaults?.set(false, forKey: "enable_haptics")
        ClipboardHistoryManager.shared.clearAll()
    }

    func testMaxItemsCap() {
        let manager = ClipboardHistoryManager.shared
        for i in 0..<60 {
            manager.addItem(content: "Item \(i)")
        }
        XCTAssertEqual(manager.items.count, 50)
    }

    func testHandleMemoryWarningTrimsItems() {
        let manager = ClipboardHistoryManager.shared
        for i in 0..<10 {
            manager.addItem(content: "Item \(i)")
        }
        manager.handleMemoryWarning()
        XCTAssertEqual(manager.items.count, 5)
    }

    func testExpiredItemsRemovedOnReload() {
        let expired = ClipboardItem(content: "Old", timestamp: Date(timeIntervalSinceNow: -172800))
        let fresh = ClipboardItem(content: "New", timestamp: Date())
        let manager = ClipboardHistoryManager.shared
        manager.reloadItemsForTesting([expired, fresh])

        XCTAssertEqual(manager.nonExpiredItems.count, 1)
        XCTAssertEqual(manager.nonExpiredItems.first?.content, "New")
    }
}
