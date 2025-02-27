import UIKit

/// Manages haptic feedback with optimized performance
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
    
    init() {
        // Prepare generators on initialization to reduce first-time latency
        prepareAll()
    }
    
    func prepareAll() {
        guard isEnabled else { return }
        
        keyPressGenerator.prepare()
        aiButtonGenerator.prepare()
        notificationGenerator.prepare()
    }
    
    func keyPress() {
        guard isEnabled else { return }
        keyPressGenerator.impactOccurred()
        // Re-prepare for next use
        keyPressGenerator.prepare()
    }
    
    func aiButtonPress() {
        guard isEnabled else { return }
        aiButtonGenerator.impactOccurred()
        // Re-prepare for next use
        aiButtonGenerator.prepare()
    }
    
    func error() {
        guard isEnabled else { return }
        notificationGenerator.notificationOccurred(.error)
        // Re-prepare for next use
        notificationGenerator.prepare()
    }
    
    func success() {
        guard isEnabled else { return }
        notificationGenerator.notificationOccurred(.success)
        // Re-prepare for next use
        notificationGenerator.prepare()
    }
}
