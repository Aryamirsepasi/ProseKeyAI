//
//  CommandsGridView.swift
//  ProseKey AI
//
//  Created by Arya Mirsepasi on 04.08.25.
//

import SwiftUI

struct AICommandButton: View {
    let command: KeyboardCommand
    let action: () -> Void
    
    @State private var isPressed = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: {
          HapticsManager.shared.keyPress()
          action()
        }) {
            VStack(spacing: 6) {
                Image(systemName: command.icon)
                    .font(.system(size: 22))
                    .foregroundColor(.primary)
                    .frame(height: 24)
                    .accessibility(hidden: false)
                
                Text(command.name)
                    .font(.system(size: 14))
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isPressed
                          ? Color(.systemGray4)
                          : (colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray6)))
                    .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isPressed ? Color.blue.opacity(0.5) : Color(.systemGray4), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(command.name)
        .simultaneousGesture(
             DragGesture(minimumDistance: 0)
               .onChanged { _ in isPressed = true }
               .onEnded { _ in isPressed = false }
           )
    }
}


struct CommandsGridView: View {
    let commands: [KeyboardCommand]
    let onCommandSelected: (KeyboardCommand) -> Void
    let isDisabled: Bool
    
    var body: some View {
        LazyVGrid(
            columns: [
                GridItem(.adaptive(minimum: 90, maximum: 110), spacing: 12)
            ],
            spacing: 12
        ) {
            ForEach(commands) { cmd in
                AICommandButton(command: cmd) {
                    onCommandSelected(cmd)
                }
                .disabled(isDisabled)
                .opacity(isDisabled ? 0.6 : 1.0)
            }
        }
        .padding(.bottom, 8)
    }
}

