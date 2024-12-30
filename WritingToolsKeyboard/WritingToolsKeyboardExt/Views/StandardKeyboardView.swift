import SwiftUI

struct StandardKeyboardView: View {
    weak var viewController: KeyboardViewController?
    var onAIButtonTapped: () -> Void
    
    @State private var capsLocked = false
    @State private var showSymbols = false
    
    let letterRows = [
        ["Q","W","E","R","T","Y","U","I","O","P"],
        ["A","S","D","F","G","H","J","K","L"],
        ["⇧","Z","X","C","V","B","N","M","⌫"]
    ]
    
    let numberRow = ["1","2","3","4","5","6","7","8","9","0"]
    
    var body: some View {
        VStack(spacing: 6) {
            // Number row
            HStack(spacing: 4) {
                ForEach(numberRow, id: \.self) { key in
                    KeyButton(text: key) {
                        viewController?.insertText(key)
                    }
                }
            }
            
            // Letter rows
            ForEach(letterRows, id: \.self) { row in
                HStack(spacing: 4) {
                    ForEach(row, id: \.self) { key in
                        KeyButton(text: key) {
                            handleKeyPress(key)
                        }
                    }
                }
            }
            
            // Bottom row
            HStack(spacing: 4) {
                KeyButton(text: "space", width: 200) {
                    viewController?.handleSpace()
                }
                
                KeyButton(text: "return", width: 80) {
                    viewController?.handleReturn()
                }
                
                KeyButton(text: "AI", width: 40) {
                    onAIButtonTapped()
                }
                .foregroundColor(.blue)
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 8)
    }
    
    private func handleKeyPress(_ key: String) {
        switch key {
        case "⌫":
            viewController?.deleteBackward()
        case "⇧":
            capsLocked.toggle()
        default:
            let text = capsLocked ? key.uppercased() : key.lowercased()
            viewController?.insertText(text)
        }
    }
}
