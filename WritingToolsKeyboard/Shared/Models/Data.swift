import SwiftUI
import SwiftData

enum Role: String, Codable {
    case assistant
    case user
    case system
}

class AppManager: ObservableObject {
    @AppStorage("systemPrompt") var systemPrompt = "You are a helpful assistant"
    @AppStorage("currentModelName") var currentModelName: String?
    @AppStorage("shouldPlayHaptics") var shouldPlayHaptics = true
    
    var userInterfaceIdiom: LayoutType {
        #if os(iOS)
        return UIDevice.current.userInterfaceIdiom == .pad ? .pad : .phone
        #else
        return .unknown
        #endif
    }

    enum LayoutType {
        case phone, pad, unknown
    }
    
    
    func playHaptic() {
        if shouldPlayHaptics {
            #if os(iOS)
            let impact = UIImpactFeedbackGenerator(style: .soft)
            impact.impactOccurred()
            #endif
        }
    }

}
