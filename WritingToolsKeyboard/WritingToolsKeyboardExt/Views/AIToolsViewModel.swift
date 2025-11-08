import Combine
import UIKit

@MainActor
class AIToolsViewModel: ObservableObject {
    @Published var selectedText: String?
    @Published var currentError: AIError?
    
    weak var viewController: KeyboardViewController?
    
    private let hapticsManager = HapticsManager.shared
    
    // Debouncing to avoid excessive checks
    private var checkTextTask: Task<Void, Never>?
    
    init(viewController: KeyboardViewController?) {
        self.viewController = viewController
        // Automatically check for selected text when initialized
        checkSelectedText()
    }
    
    func checkSelectedText() {
        // Cancel any pending check
        checkTextTask?.cancel()
        
        checkTextTask = Task { @MainActor in
            // Small delay to debounce rapid calls
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            
            guard !Task.isCancelled else { return }
            
            let docText = viewController?.getSelectedText() ?? ""
            selectedText = docText.isEmpty ? nil : docText
        }
    }
    
    func handleCopiedText() {
        Task { @MainActor in
            // Check if keyboard has full access before attempting to read from pasteboard
            guard viewController?.hasFullAccess == true else {
                currentError = .generic("Full Access required")
                selectedText = nil
                return
            }
            
            let clipboardText = UIPasteboard.general.string ?? ""
            
            if !clipboardText.isEmpty {
                selectedText = clipboardText
                currentError = nil
                ClipboardHistoryManager.shared.addItem(content: clipboardText)
            } else {
                currentError = .emptyClipboard
                selectedText = nil
            }
        }
    }
    
    /// Sets an error from any Error type
    func setError(_ error: Error) {
        if let aiError = error as? AIError {
            currentError = aiError
        } else {
            currentError = AIError.from(error)
        }
    }
    
    /// Clears the current error
    func clearError() {
        currentError = nil
    }
}

