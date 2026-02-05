import UIKit

enum ReplaceOutcome: Equatable {
    case replacedSelection
    case replacedBySearch
    case insertedAtCursorFallback
}

protocol TextDocumentProxyEditing: AnyObject {
    var selectedText: String? { get }
    func insertText(_ text: String)
    func deleteBackward()
}

/// Wraps any UITextDocumentProxy to conform to TextDocumentProxyEditing,
/// since protocol extensions cannot declare conformance to other protocols.
final class DocumentProxyWrapper: TextDocumentProxyEditing {
    private let proxy: UITextDocumentProxy

    init(_ proxy: UITextDocumentProxy) {
        self.proxy = proxy
    }

    var selectedText: String? { proxy.selectedText }
    func insertText(_ text: String) { proxy.insertText(text) }
    func deleteBackward() { proxy.deleteBackward() }
}

enum TextReplacementEngine {
    @discardableResult
    static func apply(
        replacementText: String,
        originalText: String?,
        textSource: TextSource,
        proxy: TextDocumentProxyEditing,
        replaceBySearch: (String, String) -> Bool
    ) -> ReplaceOutcome {
        guard let originalText, !originalText.isEmpty else {
            proxy.insertText(replacementText)
            return .insertedAtCursorFallback
        }

        switch textSource {
        case .selection:
            if let actualSelection = proxy.selectedText, !actualSelection.isEmpty {
                proxy.insertText(replacementText)
                return .replacedSelection
            }

            if replaceBySearch(originalText, replacementText) {
                return .replacedBySearch
            }

            proxy.insertText(replacementText)
            return .insertedAtCursorFallback

        case .fallbackDetection:
            if replaceBySearch(originalText, replacementText) {
                return .replacedBySearch
            }

            proxy.insertText(replacementText)
            return .insertedAtCursorFallback

        case .clipboard:
            proxy.insertText(replacementText)
            return .insertedAtCursorFallback
        }
    }
}
