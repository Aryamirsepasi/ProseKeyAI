import UIKit

// Manages haptic feedback with optimized performance
@MainActor
final class HapticsManager {
    static let shared = HapticsManager()
    
    // Pre-initialized feedback generators to reduce latency
    private let keyPressGenerator = UIImpactFeedbackGenerator(style: KeyboardConstants.Haptics.keyPress)
    private let aiButtonGenerator = UIImpactFeedbackGenerator(style: KeyboardConstants.Haptics.aiButtonPress)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    
    private var isEnabled: Bool {
        UserDefaults(suiteName: "group.com.aryamirsepasi.writingtools")?.bool(forKey: "enable_haptics") ?? true
    }
    
    // Cache the enabled state to avoid repeated UserDefaults calls
    private var cachedIsEnabled: Bool = true
    private var lastEnabledCheck: Date = .distantPast
    private let enabledCheckInterval: TimeInterval = 1.0
    
    init() {
        // Prepare generators on initialization to reduce first-time latency
        prepareAll()
    }
    
    private func shouldCheckEnabled() -> Bool {
        Date().timeIntervalSince(lastEnabledCheck) > enabledCheckInterval
    }
    
    private func updateEnabledState() {
        if shouldCheckEnabled() {
            cachedIsEnabled = isEnabled
            lastEnabledCheck = Date()
        }
    }
    
    func prepareAll() {
        updateEnabledState()
        guard cachedIsEnabled else { return }
        
        keyPressGenerator.prepare()
        aiButtonGenerator.prepare()
        notificationGenerator.prepare()
    }
    
    func keyPress() {
        updateEnabledState()
        guard cachedIsEnabled else { return }
        keyPressGenerator.impactOccurred()
    }
    
    func aiButtonPress() {
        updateEnabledState()
        guard cachedIsEnabled else { return }
        aiButtonGenerator.impactOccurred()
    }
    
    func error() {
        updateEnabledState()
        guard cachedIsEnabled else { return }
        notificationGenerator.notificationOccurred(.error)
    }
    
    func success() {
        updateEnabledState()
        guard cachedIsEnabled else { return }
        notificationGenerator.notificationOccurred(.success)
    }
}
