import Combine
import UIKit

@MainActor
class AIToolsViewModel: ObservableObject {
    @Published var selectedText: String?
    @Published var errorMessage: String?
    
    weak var viewController: KeyboardViewController?
    
    private lazy var hapticsManager = HapticsManager()
    
    init(viewController: KeyboardViewController?) {
            self.viewController = viewController
        }
    
    func checkSelectedText() {
        Task { @MainActor in
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
               } else {
                   errorMessage = "Clipboard is empty"
                   selectedText = nil
               }
           }
       }
}
