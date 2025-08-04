import SwiftUI

struct CustomPromptView: View {
    @Binding var prompt: String
    let selectedText: String
    let onSubmit: (String) -> Void
    let onCancel: () -> Void
    
    @State private var cursorPosition = 0
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header 
            HStack {
              Button(action: onCancel) {
                Image(systemName: "chevron.left")
                  .font(.system(size: 15, weight: .medium))
                Text("Back").font(.system(size: 15, weight: .medium))
              }
              .foregroundColor(.blue)

              Spacer()
              Text("Custom Prompt").font(.subheadline).fontWeight(.semibold)
              Spacer()

              Button("Submit") {
                let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty { onSubmit(trimmed) }
              }
              .font(.system(size: 15, weight: .medium))
              .foregroundColor(prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .blue)
              .disabled(prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(.systemGray6))
            
            // Compact text preview (one row like main view)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Selected Text:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                    Spacer()
                }
                .padding(.horizontal)
                
                HStack {
                    ScrollView(.horizontal, showsIndicators: false) {
                        Text(selectedText)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(6)
                    .overlay(
                        HStack {
                            Spacer()
                            if selectedText.count > 30 {
                                LinearGradient(
                                    gradient: Gradient(colors: [.clear, Color(.systemGray6)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                .frame(width: 20)
                            }
                        }
                    )
                }
                .padding(.horizontal)
            }
            
            // Prompt input area
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Your Prompt:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                TextField("Type your custom instructions for the AI…", text: $prompt)
                  .font(.system(size: 15))
                  .frame(height: 32) // was 40
                  .padding(.horizontal, 8)
                  .background(
                    RoundedRectangle(cornerRadius: 8)
                      .stroke(Color.purple, lineWidth: 1.5)
                  )
                  .padding(.horizontal, 10)
                  .padding(.top, 6)
                  .padding(.bottom, 6)
                  .focused($isTextFieldFocused)
            }
            
            // Custom Keyboard
            CustomInstructionKeyboardRepresentable(
              text: $prompt,
              cursorPosition: $cursorPosition,
              onReturn: {
                let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty { onSubmit(trimmed) }
              }
            )
            .frame(height: 190)
            .background(Color(.systemGray5))
        }
        
        .onAppear {
            isTextFieldFocused = true
        }
    }
}

struct CustomKeyboardView: View {
    @Binding var text: String
    @Binding var cursorPosition: Int
    let onReturn: () -> Void
    
    @State private var isShifted = false
    @State private var isSymbolMode = false
    @State private var capsLockEnabled = false
    @State private var currentSymbolsPage = 1
    
    private let qwertyRows: [[String]] = [
        ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
        ["a", "s", "d", "f", "g", "h", "j", "k", "l"],
        ["z", "x", "c", "v", "b", "n", "m"]
    ]
    
    
    private let symbolsPage1: [[String]] = [
        ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"],
        ["-", "/", ":", ";", "(", ")", "$", "&", "@", "\""],
        [".", ",", "?", "!", "'"]
    ]
    
    private let symbolsPage2: [[String]] = [
            ["[", "]", "{", "}", "#", "%", "^", "*", "+", "="],
            ["_", "\\", "|", "~", "<", ">", "€", "£", "¥", "•"],
            [".", ",", "?", "!", "'"]
        ]
    
    var body: some View {
        VStack(spacing: 8) {
            
            if isSymbolMode {
                symbolKeyboard
            } else {
                letterKeyboard
            }
            
            // Bottom row with return button
            HStack(spacing: 4) {
                KeyButton(
                    text: isSymbolMode ? "ABC" : "123",
                    action: { isSymbolMode.toggle() },
                    backgroundColor: Color(.systemGray4)
                )
                .frame(width: 50)
                
                KeyButton(
                    text: "space",
                    action: { insertText(" ") }
                )
                .frame(maxWidth: .infinity)
                
                KeyButton(
                    text: "return",
                    action: onReturn,
                    backgroundColor: Color(.systemGray4)
                )
                .frame(width: 60)
            }
            .padding(.horizontal, 8)
        }
    }
    
    private var letterKeyboard: some View {
        VStack(spacing: 6) {
            // First row
            HStack(spacing: 4) {
                ForEach(qwertyRows[0], id: \.self) { letter in
                    KeyButton(
                        text: displayText(for: letter),
                        action: { insertText(displayText(for: letter)) }
                    )
                }
            }
            .padding(.horizontal, 8)
            
            // Second row
            HStack(spacing: 4) {
                ForEach(qwertyRows[1], id: \.self) { letter in
                    KeyButton(
                        text: displayText(for: letter),
                        action: { insertText(displayText(for: letter)) }
                    )
                }
            }
            .padding(.horizontal, 20)
            
            // Third row with shift and delete
            HStack(spacing: 4) {
                KeyButton(
                    text: "⇧",
                    action: toggleShift,
                    backgroundColor: (isShifted || capsLockEnabled) ? Color.blue.opacity(0.3) : Color(.systemGray4)
                )
                .frame(width: 40)
                
                ForEach(qwertyRows[2], id: \.self) { letter in
                    KeyButton(
                        text: displayText(for: letter),
                        action: { insertText(displayText(for: letter)) }
                    )
                }
                
                KeyButton(
                    text: "⌫",
                    action: deleteText,
                    backgroundColor: Color(.systemGray4)
                )
                .frame(width: 40)
            }
            .padding(.horizontal, 8)
        }
    }
    
    private var symbolKeyboard: some View {
        
        let symbols = currentSymbolsPage == 1 ? symbolsPage1 : symbolsPage2

        return VStack(spacing: 6) {

            // First symbol row
            HStack(spacing: 4) {
                ForEach(symbols[0], id: \.self) { symbol in
                    KeyButton(
                        text: symbol,
                        action: { insertText(symbol) }
                    )
                }
            }
            .padding(.horizontal, 8)
            
            // Second symbol row
            HStack(spacing: 4) {
                ForEach(symbols[1], id: \.self) { symbol in
                    KeyButton(
                        text: symbol,
                        action: { insertText(symbol) }
                    )
                }
            }
            .padding(.horizontal, 20)
            
            // Third symbol row with modifier keys
            HStack(spacing: 4) {
                KeyButton(
                    text: "#+",
                    action: {
                        currentSymbolsPage = (currentSymbolsPage == 1) ? 2 : 1
                    },
                    backgroundColor: Color(.systemGray4)
                )
                .frame(width: 40)
                
                ForEach(symbols[2], id: \.self) { symbol in
                    KeyButton(
                        text: symbol,
                        action: { insertText(symbol) }
                    )
                }
                
                KeyButton(
                    text: "⌫",
                    action: deleteText,
                    backgroundColor: Color(.systemGray4)
                )
                .frame(width: 40)
            }
            .padding(.horizontal, 8)
        }
    }
    
    private func displayText(for letter: String) -> String {
        if isShifted || capsLockEnabled {
            return letter.uppercased()
        }
        return letter
    }
    
    private func insertText(_ newText: String) {
        let insertionIndex = text.index(text.startIndex, offsetBy: min(cursorPosition, text.count))
        text.insert(contentsOf: newText, at: insertionIndex)
        cursorPosition += newText.count
        
        // Reset shift after typing (except for caps lock)
        if isShifted && !capsLockEnabled {
            isShifted = false
        }
        
        // Haptic feedback
        if UserDefaults(suiteName: "group.com.aryamirsepasi.writingtools")?.bool(forKey: "enable_haptics") ?? true {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
    
    private func deleteText() {
        guard cursorPosition > 0 && !text.isEmpty else { return }
        
        let deletionIndex = text.index(text.startIndex, offsetBy: cursorPosition - 1)
        text.remove(at: deletionIndex)
        cursorPosition -= 1
        
        // Haptic feedback
        if UserDefaults(suiteName: "group.com.aryamirsepasi.writingtools")?.bool(forKey: "enable_haptics") ?? true {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
    
    private func toggleShift() {
        if capsLockEnabled {
            // If currently in caps lock, pressing shift again resets both shift and caps lock
            capsLockEnabled = false
            isShifted = false
        } else if isShifted {
            // Double tap: enable caps lock
            capsLockEnabled = true
            isShifted = false
        } else {
            // Single tap: enable shift
            isShifted = true
            capsLockEnabled = false
        }
        // Haptic feedback
        if UserDefaults(suiteName: "group.com.aryamirsepasi.writingtools")?.bool(forKey: "enable_haptics") ?? true {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }
}

struct KeyButton: View {
    let text: String
    let action: () -> Void
    var backgroundColor: Color = Color(.systemGray6)
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Text(text == "space" ? "" : text)
                .font(.system(size: text.count == 1 ? 18 : 14, weight: .medium))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isPressed ? backgroundColor.opacity(0.8) : backgroundColor)
                        .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(.systemGray4), lineWidth: 0.5)
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
