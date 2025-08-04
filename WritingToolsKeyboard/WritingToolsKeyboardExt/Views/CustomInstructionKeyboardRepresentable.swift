//
//  CustomInstructionKeyboardRepresentable.swift
//  ProseKey AI
//
//  Created by Arya Mirsepasi on 04.08.25.
//

import SwiftUI

struct CustomInstructionKeyboardRepresentable: UIViewRepresentable {
  @Binding var text: String
  @Binding var cursorPosition: Int
  let onReturn: () -> Void

  func makeUIView(context: Context) -> CustomInstructionKeyboardView {
    let v = CustomInstructionKeyboardView()
    v.delegate = context.coordinator
    return v
  }

  func updateUIView(_ uiView: CustomInstructionKeyboardView, context: Context) {
    // nothing to sync right now; keyboard is stateless wrt external changes
  }
    

  func makeCoordinator() -> Coordinator {
    Coordinator(text: $text, cursorPosition: $cursorPosition, onReturn: onReturn)
  }

    final class Coordinator: NSObject, @preconcurrency CustomInstructionKeyboardDelegate {
    @Binding var text: String
    @Binding var cursorPosition: Int
    let onReturn: () -> Void

    init(text: Binding<String>, cursorPosition: Binding<Int>, onReturn: @escaping () -> Void) {
      _text = text
      _cursorPosition = cursorPosition
      self.onReturn = onReturn
    }

      @MainActor func keyboardInsert(_ t: String) {
      let idx = text.index(text.startIndex, offsetBy: min(cursorPosition, text.count))
      text.insert(contentsOf: t, at: idx)
      cursorPosition += t.count
      HapticsManager.shared.keyPress()
    }

        @MainActor func keyboardDeleteBackward() {
      guard cursorPosition > 0 && !text.isEmpty else { return }
      let idx = text.index(text.startIndex, offsetBy: cursorPosition - 1)
      text.remove(at: idx)
      cursorPosition -= 1
      HapticsManager.shared.keyPress()
    }

        @MainActor func keyboardReturn() {
      onReturn()
      HapticsManager.shared.aiButtonPress()
    }

    func keyboardToggleSymbols() { /* no-op; UI handles */ }

        @MainActor func keyboardToggleShift(mode: CustomInstructionKeyboardView.ShiftMode) {
      HapticsManager.shared.aiButtonPress()
    }

        @MainActor func keyboardSwitchSymbolsPage(_ page: Int) {
      HapticsManager.shared.keyPress()
    }
  }
}
