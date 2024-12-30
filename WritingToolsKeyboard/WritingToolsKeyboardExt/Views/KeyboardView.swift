import SwiftUI

/// SHIFT states
enum ShiftState {
    case lower    // default
    case once     // shift pressed once
    case locked   // caps lock
}

struct KeyboardView: View {
    weak var viewController: KeyboardViewController?
    
    @State private var showAITools = false
    @State private var selectedText: String?
    
    // Toggles from shared defaults
    @AppStorage("show_number_row", store: UserDefaults(suiteName: "group.com.aryamirsepasi.writingtools"))
    private var showNumberRow = true
    
    @AppStorage("enable_suggestions", store: UserDefaults(suiteName: "group.com.aryamirsepasi.writingtools"))
    private var enableSuggestions = true
    
    @AppStorage("enable_haptics", store: UserDefaults(suiteName: "group.com.aryamirsepasi.writingtools"))
    private var enableHaptics = true
    
    // SHIFT + Symbols
    @State private var shiftState: ShiftState = .lower
    @State private var showSymbols = false
    
    // Suggestions
    @State private var suggestions: [String] = []
    private let keyboardManager = KeyboardManager()
    
    // Key sizing
    private let letterKeyWidth: CGFloat  = 34
    private let letterKeyHeight: CGFloat = 42
    private let returnKeyWidth: CGFloat  = 90
    private let bottomRowKeyHeight: CGFloat = 44
    
    // bigger width for SHIFT and DELETE
    private let specialKeyWidth: CGFloat = 50
    
    var body: some View {
        VStack(spacing: 0) {
            // Add a little top padding to separate from the host app's content
            Spacer(minLength: 6)
            
            // Always show suggestions row if suggestions are enabled
            if enableSuggestions {
                HStack(spacing: 8) {
                    if suggestions.isEmpty {
                        Text(" ")
                            .frame(height: 1) // invisible placeholder to keep row height
                    } else {
                        ForEach(suggestions, id: \.self) { suggestion in
                            Button {
                                insertSuggestion(suggestion)
                            } label: {
                                Text(suggestion)
                                    .font(.system(size: 16))
                                    .foregroundColor(.primary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 6)
                                    .background(Color(UIColor.systemGray6))
                                    .cornerRadius(5)
                            }
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 6)
            }
            
            if showAITools {
                AIToolsView(selectedText: $selectedText) {
                    withAnimation { showAITools = false }
                }
            } else {
                // Main keyboard
                VStack(spacing: 6) {
                    // Number row, only if toggled on and not in symbol mode
                    if showNumberRow && !showSymbols {
                        HStack(spacing: 4) {
                            ForEach(numberRow, id: \.self) { key in
                                KeyButton(
                                    text: key,
                                    width: letterKeyWidth,
                                    height: letterKeyHeight,
                                    enableHaptics: enableHaptics
                                ) {
                                    viewController?.insertText(key)
                                    updateSuggestions()
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    
                    // Main rows: either letters or symbols
                    ForEach(currentRows, id: \.self) { row in
                        HStack(spacing: 4) {
                            ForEach(row, id: \.self) { key in
                                let isShift = (key == "⇧")
                                let isDelete = (key == "⌫")
                                let keyWidth = (isShift || isDelete) ? specialKeyWidth : letterKeyWidth
                                
                                KeyButton(
                                    text: key,
                                    width: keyWidth,
                                    height: letterKeyHeight,
                                    enableHaptics: enableHaptics
                                ) {
                                    handleKeyPress(key)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    
                    // Bottom row
                    HStack(spacing: 4) {
                        KeyButton(
                            text: showSymbols ? "ABC" : "123",
                            width: 50,
                            height: bottomRowKeyHeight,
                            enableHaptics: enableHaptics
                        ) {
                            toggleSymbols()
                        }
                        
                        Button {
                            guard viewController?.hasFullAccess == true else { return }
                            let docText = viewController?.getSelectedText() ?? ""
                            selectedText = docText.isEmpty ? "" : docText
                            withAnimation { showAITools = true }
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: "wand.and.stars")
                                    .font(.system(size: 16, weight: .medium))
                                Text("AI")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .frame(width: 60, height: bottomRowKeyHeight)
                            .background(Color.blue)
                            .cornerRadius(8)
                        }
                        
                        KeyButton(
                            text: "space",
                            width: 150,
                            height: bottomRowKeyHeight,
                            enableHaptics: enableHaptics
                        ) {
                            viewController?.handleSpace()
                            updateSuggestions()
                        }
                        
                        KeyButton(
                            text: "return",
                            width: returnKeyWidth,
                            height: bottomRowKeyHeight,
                            enableHaptics: enableHaptics
                        ) {
                            viewController?.handleReturn()
                            updateSuggestions()
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity)
            }
        }
        // Make sure the background is fully clear to reveal the blur
        .background(Color.clear)
        .ignoresSafeArea(.container, edges: .all)
    }
}

// MARK: - SHIFT & SYMBOLS

extension KeyboardView {
    private var baseLetterRows: [[String]] {
        [
            ["Q","W","E","R","T","Y","U","I","O","P"],
            ["A","S","D","F","G","H","J","K","L"],
            ["⇧","Z","X","C","V","B","N","M","⌫"]
        ]
    }
    
    private var symbolRows: [[String]] {
        [
            ["1","2","3","4","5","6","7","8","9","0"],
            ["-","/",":",";","(",")","$","&","@","\\"],
            ["`","´","%","+", "-", "*", "=", "_", "^", "~"],
            [".",",","?","!","'","[","]","{","}","⌫"]
        ]
    }
    
    private var currentRows: [[String]] {
        if showSymbols {
            return symbolRows
        } else {
            return displayLetterRows()
        }
    }
    
    private var numberRow: [String] {
        ["1","2","3","4","5","6","7","8","9","0"]
    }
    
    private func displayLetterRows() -> [[String]] {
        switch shiftState {
        case .lower:
            return baseLetterRows.map { row in
                row.map { char in
                    if char == "⇧" || char == "⌫" {
                        return char
                    }
                    return char.lowercased()
                }
            }
        case .once, .locked:
            return baseLetterRows
        }
    }
    
    private func toggleSymbols() {
        showSymbols.toggle()
    }
}

// MARK: - KEY PRESS

extension KeyboardView {
    private func handleKeyPress(_ key: String) {
        switch key {
        case "⌫":
            viewController?.deleteBackward()
        case "⇧":
            handleShift()
        default:
            insertCharacter(key)
        }
        updateSuggestions()
    }
    
    private func handleShift() {
        switch shiftState {
        case .lower:
            shiftState = .once
        case .once:
            shiftState = .locked
        case .locked:
            shiftState = .lower
        }
    }
    
    private func insertCharacter(_ key: String) {
        if key == "space" {
            viewController?.handleSpace()
            return
        }
        
        if shiftState == .once && !showSymbols {
            viewController?.insertText(key.uppercased())
            shiftState = .lower
        } else if shiftState == .locked && !showSymbols {
            viewController?.insertText(key.uppercased())
        } else {
            viewController?.insertText(key)
        }
    }
}

// MARK: - SUGGESTIONS

extension KeyboardView {
    private func updateSuggestions() {
        if !enableSuggestions || showSymbols {
            suggestions = []
            return
        }
        
        if let proxy = viewController?.textDocumentProxy,
           let text = proxy.documentContextBeforeInput {
            
            suggestions = keyboardManager.getSuggestions(for: text)
            
            // Possibly auto-correct
            if let correction = keyboardManager.getAutocorrectSuggestion(for: text) {
                let words = text.components(separatedBy: .whitespaces)
                if let lastWord = words.last {
                    for _ in 0..<lastWord.count {
                        viewController?.deleteBackward()
                    }
                }
                viewController?.insertText(correction)
            }
        } else {
            suggestions = []
        }
    }
    
    private func insertSuggestion(_ suggestion: String) {
        if let proxy = viewController?.textDocumentProxy,
           let text = proxy.documentContextBeforeInput {
            let words = text.components(separatedBy: .whitespaces)
            if let lastWord = words.last {
                for _ in 0..<lastWord.count {
                    viewController?.deleteBackward()
                }
            }
        }
        viewController?.insertText(suggestion + " ")
        updateSuggestions()
    }
}
