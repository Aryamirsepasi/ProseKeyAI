import Combine
import UIKit

@MainActor
class AIToolsViewModel: ObservableObject {
    @Published var selectedText: String?
    @Published var errorMessage: String?
    
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
            let clipboardText = UIPasteboard.general.string ?? ""
            
            if !clipboardText.isEmpty {
                selectedText = clipboardText
                errorMessage = nil
                ClipboardHistoryManager.shared.addItem(content: clipboardText)
            } else {
                errorMessage = "History is empty"
                selectedText = nil
            }
        }
    }
}

