import Foundation
import UIKit

enum KeyboardConstants {
    /// Default keyboard height optimized for 2 visible command rows.
    /// Layout breakdown:
    /// - Action buttons row: ~56pt (40pt buttons + 16pt padding)
    /// - Text preview row: ~48pt (32pt content + 16pt padding)
    /// - Commands grid: ~156pt (2 × 64pt rows + 8pt gap + 16pt padding)
    /// - Total: ~260pt
    static let keyboardHeight: CGFloat = 260
    
    /// Expanded keyboard height for views that need more space (e.g., CustomPromptView with inline keyboard).
    /// Layout breakdown:
    /// - Header: 44pt
    /// - Text preview: ~30pt
    /// - Text input field: ~48pt
    /// - Custom keyboard: 190pt
    /// - Spacers/padding: ~28pt
    /// - Total: ~340pt
    static let expandedKeyboardHeight: CGFloat = 340
    static let buttonSpacing: CGFloat = 4
    static let buttonCornerRadius: CGFloat = 6
    static let standardButtonWidth: CGFloat = 32
    static let standardButtonHeight: CGFloat = 40
    
    enum Colors {
        static let keyBackground = "systemGray6"
        static let keyBackgroundPressed = "systemGray4"
        static let keyBorder = "systemGray3"
    }
    
    enum Haptics {
        static let keyPress = UIImpactFeedbackGenerator.FeedbackStyle.light
        static let aiButtonPress = UIImpactFeedbackGenerator.FeedbackStyle.medium
        static let error = UINotificationFeedbackGenerator.FeedbackType.error
        static let success = UINotificationFeedbackGenerator.FeedbackType.success
    }
}
