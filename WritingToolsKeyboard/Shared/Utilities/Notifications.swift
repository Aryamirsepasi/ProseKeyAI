import Foundation
import CoreFoundation

enum AppNotifications {
    static let keyboardCommandsDidChange = "com.aryamirsepasi.writingtools.commandsUpdated"
}

extension Notification.Name {
    static let keyboardCommandsDidChange = Notification.Name(AppNotifications.keyboardCommandsDidChange)
}

@MainActor
func postKeyboardCommandsDidChange() {
    NotificationCenter.default.post(name: .keyboardCommandsDidChange, object: nil)
    CFNotificationCenterPostNotification(
        CFNotificationCenterGetDarwinNotifyCenter(),
        CFNotificationName(AppNotifications.keyboardCommandsDidChange as CFString),
        nil,
        nil,
        true
    )
}
