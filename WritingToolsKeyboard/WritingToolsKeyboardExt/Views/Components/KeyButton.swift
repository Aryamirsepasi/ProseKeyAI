import SwiftUI

struct KeyButton: View {
    let text: String
    var width: CGFloat  = 32
    var height: CGFloat = 40
    
    var enableHaptics: Bool = true
    
    let action: () -> Void
    var tag: Int? = nil
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            if enableHaptics {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            action()
        }) {
            Text(text)
                .font(.system(size: 18))
                .foregroundColor(.primary)
                .frame(width: width, height: height)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isPressed ? Color(.systemGray4) : Color(.systemGray6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(.systemGray3), lineWidth: 0.5)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed { isPressed = true }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
        .tag(tag ?? 0)
    }
}
