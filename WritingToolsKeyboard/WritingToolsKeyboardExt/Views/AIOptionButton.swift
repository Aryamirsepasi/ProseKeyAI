import SwiftUI

struct AICommandButton: View {
    let command: KeyboardCommand
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        }) {
            VStack(spacing: 4) {
                Image(systemName: command.icon)
                    .font(.system(size: 20))
                Text(command.name)
                    .font(.system(size: 14))
            }
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isPressed ? Color(.systemGray4) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.systemGray3), lineWidth: 0.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }
}

struct CommandsGridView: View {
    let commands: [KeyboardCommand]
    let onCommandSelected: (KeyboardCommand) -> Void
    let isDisabled: Bool
    
    var body: some View {
        ForEach(commands) { cmd in
            AICommandButton(command: cmd) {
                onCommandSelected(cmd)
            }
            .disabled(isDisabled)
        }
    }
}
