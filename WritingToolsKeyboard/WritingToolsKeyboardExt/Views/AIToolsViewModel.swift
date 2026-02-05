import Combine
import UIKit

enum TextSource {
    case selection          // Real iOS text selection (proxy.selectedText)
    case clipboard          // From "Use Copied" button
    case fallbackDetection  // Auto-detected from documentContext
}

@MainActor
class AIToolsViewModel: ObservableObject {
    @Published var selectedText: String?
    @Published var currentError: AIError?
    @Published var textSource: TextSource = .selection
    
    weak var viewController: KeyboardViewController?
    
    private let hapticsManager = HapticsManager.shared
    
    // Debouncing to avoid excessive checks
    private var checkTextTask: Task<Void, Never>?
    private var checkTextTaskId = UUID()
    
    init(viewController: KeyboardViewController?) {
        self.viewController = viewController
        // Automatically check for selected text when initialized
        checkSelectedText()
    }
    
    func checkSelectedText() {
        // Cancel any pending check
        checkTextTask?.cancel()

        let taskId = UUID()
        checkTextTaskId = taskId

        checkTextTask = Task { @MainActor in
            // Small delay to debounce rapid calls
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            
            guard !Task.isCancelled else { return }
            guard taskId == checkTextTaskId else { return }
            
            let docText = viewController?.getSelectedText() ?? ""
            if docText.isEmpty {
                selectedText = nil
            } else {
                selectedText = docText
                // Determine if this came from a real selection or fallback detection
                if let proxy = viewController?.textDocumentProxy,
                   let realSelection = proxy.selectedText, !realSelection.isEmpty {
                    textSource = .selection
                } else {
                    textSource = .fallbackDetection
                }
            }
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
                textSource = .clipboard
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

    // MARK: - Memory Warning Handler

    /// Cleans up resources to free memory
    func handleMemoryWarning() {
        checkTextTask?.cancel()
        checkTextTask = nil
        selectedText = nil
        currentError = nil
    }
}
