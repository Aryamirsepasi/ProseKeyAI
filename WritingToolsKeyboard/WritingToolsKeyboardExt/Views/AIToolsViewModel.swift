import Combine
import UIKit

@MainActor
class AIToolsViewModel: ObservableObject {
    @Published var selectedText: String?
    @Published var errorMessage: String?
    
    weak var viewController: KeyboardViewController?
    
    init(viewController: KeyboardViewController?) {
            self.viewController = viewController
            checkSelectedText()
        }
    
    func checkSelectedText() {
        let docText = viewController?.getSelectedText() ?? ""
        selectedText = docText.isEmpty ? nil : docText
    }
    
    func handleCopiedText() {
           // Always attempt to use clipboard
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