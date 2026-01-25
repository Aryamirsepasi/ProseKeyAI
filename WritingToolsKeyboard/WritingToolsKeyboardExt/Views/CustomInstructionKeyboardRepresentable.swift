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
    }

    @MainActor func keyboardDeleteWord() {
      guard cursorPosition > 0 && !text.isEmpty else { return }

      let currentIdx = text.index(text.startIndex, offsetBy: cursorPosition)
      let textBefore = text[text.startIndex..<currentIdx]

      // Find the start of the current/previous word
      // Skip any trailing whitespace first
      var deleteEnd = cursorPosition
      var searchIdx = textBefore.endIndex

      // Skip trailing spaces
      while searchIdx > textBefore.startIndex {
        let prevIdx = textBefore.index(before: searchIdx)
        if !textBefore[prevIdx].isWhitespace {
          break
        }
        searchIdx = prevIdx
        deleteEnd -= 1
      }

      // Now find the start of the word (stop at whitespace or punctuation)
      while searchIdx > textBefore.startIndex {
        let prevIdx = textBefore.index(before: searchIdx)
        let char = textBefore[prevIdx]
        if char.isWhitespace || char.isPunctuation {
          break
        }
        searchIdx = prevIdx
      }

      let deleteStart = textBefore.distance(from: textBefore.startIndex, to: searchIdx)
      let charsToDelete = cursorPosition - deleteStart

      // Delete the characters
      if charsToDelete > 0 {
        let rangeStart = text.index(text.startIndex, offsetBy: deleteStart)
        let rangeEnd = text.index(text.startIndex, offsetBy: cursorPosition)
        text.removeSubrange(rangeStart..<rangeEnd)
        cursorPosition = deleteStart
      }
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
