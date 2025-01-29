import SwiftUI

struct AIOptionButton: View {
    let option: WritingOption
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        }) {
            VStack(spacing: 4) {
                Image(systemName: option.icon)
                    .font(.system(size: 20))
                Text(option.rawValue)
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

struct CustomAIOptionButton: View {
    let command: CustomCommand
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

struct CustomToolsGridView: View {
    let commands: [CustomCommand]
    let onCommandSelected: (CustomCommand) -> Void
    
    var body: some View {
        ForEach(commands, id: \.id) { cmd in
            CustomAIOptionButton(command: cmd) {
                onCommandSelected(cmd)
            }
        }
    }
}