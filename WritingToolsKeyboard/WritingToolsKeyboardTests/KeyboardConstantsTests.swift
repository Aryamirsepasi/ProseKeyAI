import XCTest
@testable import ProseKey_AI

final class KeyboardConstantsTests: XCTestCase {

    // MARK: - Layout values

    func testKeyboardHeightIsReasonable() {
        XCTAssertEqual(KeyboardConstants.keyboardHeight, 260)
        XCTAssertGreaterThan(KeyboardConstants.keyboardHeight, 0)
    }

    func testExpandedKeyboardHeightIsLargerThanDefault() {
        XCTAssertEqual(KeyboardConstants.expandedKeyboardHeight, 340)
        XCTAssertGreaterThan(KeyboardConstants.expandedKeyboardHeight,
                             KeyboardConstants.keyboardHeight)
    }

    func testButtonSpacing() {
        XCTAssertEqual(KeyboardConstants.buttonSpacing, 4)
    }

    func testButtonCornerRadius() {
        XCTAssertEqual(KeyboardConstants.buttonCornerRadius, 6)
    }

    func testStandardButtonDimensions() {
        XCTAssertEqual(KeyboardConstants.standardButtonWidth, 32)
        XCTAssertEqual(KeyboardConstants.standardButtonHeight, 40)
        XCTAssertGreaterThan(KeyboardConstants.standardButtonHeight,
                             KeyboardConstants.standardButtonWidth)
    }

    // MARK: - Color names

    func testColorStringsAreNonEmpty() {
        XCTAssertFalse(KeyboardConstants.Colors.keyBackground.isEmpty)
        XCTAssertFalse(KeyboardConstants.Colors.keyBackgroundPressed.isEmpty)
        XCTAssertFalse(KeyboardConstants.Colors.keyBorder.isEmpty)
    }

    // MARK: - Haptics constants

    func testHapticStyles() {
        XCTAssertEqual(KeyboardConstants.Haptics.keyPress, .light)
        XCTAssertEqual(KeyboardConstants.Haptics.aiButtonPress, .medium)
        XCTAssertEqual(KeyboardConstants.Haptics.error, .error)
        XCTAssertEqual(KeyboardConstants.Haptics.success, .success)
    }
}
