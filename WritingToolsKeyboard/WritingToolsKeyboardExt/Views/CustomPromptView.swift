import SwiftUI

struct CustomPromptView: View {
    let selectedText: String
    let onSubmit: (String) -> Void
    let onCancel: () -> Void

    @Binding var prompt: String
    @State private var cursorPosition = 0
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header - matching ClipboardHistoryView style (44pt + divider)
            HStack {
                Button(action: onCancel) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 17))
                    }
                    .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                Text("Custom Prompt")
                    .font(.system(size: 17, weight: .semibold))
                
                Spacer()
                
                Button("Submit") {
                    let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty { onSubmit(trimmed) }
                }
                .font(.system(size: 17))
                .foregroundColor(prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .blue)
                .disabled(prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(height: 44)
            
            Divider()
            
            Spacer()
            
            // Text preview - compact single row
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
            .padding(.horizontal, 12)
            .padding(.top, 8)
            
            Spacer()
            
            // Text input field
            TextField("Type your custom instructions for the AI…", text: $prompt)
                .font(.system(size: 15))
                .frame(height: 32)
                .padding(.horizontal, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.purple, lineWidth: 1.5)
                )
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 8)
                .focused($isTextFieldFocused)
            
            
            Spacer()
            
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
        let safeCursor = max(0, min(cursorPosition, text.count))
        let insertionIndex = text.index(text.startIndex, offsetBy: safeCursor)
        text.insert(contentsOf: newText, at: insertionIndex)
        cursorPosition = safeCursor + newText.count
        
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
