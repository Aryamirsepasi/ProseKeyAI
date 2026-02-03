import SwiftUI

private struct AICommandCardStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray5))
                    .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(configuration.isPressed ? Color.blue.opacity(0.5) : Color(.systemGray4), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .contentShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct AICommandButton: View {
    let command: KeyboardCommand
    let isDisabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticsManager.shared.keyPress()
            action()
        }) {
            VStack(spacing: 6) {
                Image(systemName: command.icon)
                    .font(.title3)
                    .foregroundStyle(.primary)
                    .frame(height: 24)
                    .accessibility(hidden: false)
                
                Text(command.displayName)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .buttonStyle(AICommandCardStyle())
        .accessibilityLabel(command.displayName)
        .opacity(isDisabled ? 0.5 : 1.0)
        .allowsHitTesting(!isDisabled)
    }
}

struct CommandsGridView: View {
    let commands: [KeyboardCommand]
    let onCommandSelected: (KeyboardCommand) -> Void
    let isDisabled: Bool
    
    // Fixed 4-column layout
    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(commands) { cmd in
                AICommandButton(
                    command: cmd,
                    isDisabled: isDisabled,
                    action: { onCommandSelected(cmd) }
                )
            }
        }
        .padding(.vertical, 8)
    }
}
