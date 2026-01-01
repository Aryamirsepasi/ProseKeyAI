import Foundation
import UIKit

enum KeyboardConstants {
    static let keyboardHeight: CGFloat = 340
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
