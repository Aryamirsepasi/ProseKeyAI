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
    
    @AppStorage("enable_haptics", store: UserDefaults(suiteName: "group.com.aryamirsepasi.writingtools"))
    private var enableHaptics = true
    
    @State private var shiftState: ShiftState = .lower
    @State private var showSymbols = false
    
    // Key sizing
    private let letterKeyWidth: CGFloat  = 34
    private let letterKeyHeight: CGFloat = 42
    private let returnKeyWidth: CGFloat  = 90
    private let bottomRowKeyHeight: CGFloat = 44
    
    // bigger width for SHIFT and DELETE
    private let specialKeyWidth: CGFloat = 50
    
    var body: some View {
        VStack(spacing: 0) {
            // Some top padding
            Spacer(minLength: 6)
            
            if showAITools {
                AIToolsView(selectedText: $selectedText) {
                    withAnimation { showAITools = false }
                }
            } else {
                // Main keyboard
                VStack(spacing: 6) {
                    
                    // Only show the separate number row when NOT in symbol mode
                    if !showSymbols {
                        HStack(spacing: 4) {
                            ForEach(numberRow, id: \.self) { key in
                                KeyButton(
                                    text: key,
                                    width: letterKeyWidth,
                                    height: letterKeyHeight,
                                    enableHaptics: enableHaptics
                                ) {
                                    viewController?.insertText(key)
                                }
                            }
                        }
                    }
                    
                    // Main rows (alphabetic or symbols)
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
                        }
                        
                        KeyButton(
                            text: "return",
                            width: returnKeyWidth,
                            height: bottomRowKeyHeight,
                            enableHaptics: enableHaptics
                        ) {
                            viewController?.handleReturn()
                        }
                    }
                }
            }
        }
        // Make sure the background is clear to reveal the blur behind it
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
    
    // Symbol layout already includes numbers in its top row
    private var symbolRows: [[String]] {
        [
            ["1","2","3","4","5","6","7","8","9","0"],
            ["-","/",":",";","(",")","$","&","@","\\"],
            ["`","´","%","+", "-", "*", "=", "_", "^", "~"],
            [".",",","?","!","'","[","]","{","}","⌫"]
        ]
    }
    
    private var currentRows: [[String]] {
        showSymbols ? symbolRows : displayLetterRows()
    }
    
    // This is the separate number row for alphabetical mode only
    private var numberRow: [String] {
        ["1","2","3","4","5","6","7","8","9","0"]
    }
    
    private func displayLetterRows() -> [[String]] {
        switch shiftState {
        case .lower:
            return baseLetterRows.map { row in
                row.map { char in
                    (char == "⇧" || char == "⌫") ? char : char.lowercased()
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
