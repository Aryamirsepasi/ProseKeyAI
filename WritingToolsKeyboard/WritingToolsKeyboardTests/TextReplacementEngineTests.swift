import XCTest
@testable import WritingToolsKeyboardExt

final class TextReplacementEngineTests: XCTestCase {
    func testSelectionSourceWithActiveSelectionReplacesSelectedRange() {
        let proxy = FakeTextDocumentProxy(text: "Hello brave world")
        XCTAssertTrue(proxy.selectFirstOccurrence(of: "brave "))

        let outcome = TextReplacementEngine.apply(
            replacementText: "amazing ",
            originalText: "brave ",
            textSource: .selection,
            proxy: proxy
        ) { _, _ in
            XCTFail("Search replacement should not run when live selection exists")
            return false
        }

        XCTAssertEqual(outcome, .replacedSelection)
        XCTAssertEqual(proxy.text, "Hello amazing world")
    }

    func testSelectionSourceFallsBackToSearchWhenSelectionIsGone() {
        let proxy = FakeTextDocumentProxy(text: "Start target end")
        var searchCalled = false

        let outcome = TextReplacementEngine.apply(
            replacementText: "result",
            originalText: "target",
            textSource: .selection,
            proxy: proxy
        ) { original, replacement in
            searchCalled = true
            return proxy.replaceLastOccurrence(of: original, with: replacement)
        }

        XCTAssertTrue(searchCalled)
        XCTAssertEqual(outcome, .replacedBySearch)
        XCTAssertEqual(proxy.text, "Start result end")
    }

    func testFallbackDetectionRegressionForGermanSample() {
        let originalDocument = "Wir planen die Entwicklung eines Systems für „Hansa MediCare“ zur Überwachung und Steuerung aller Aktivitäten im Bereich der Neukundengewinnung. Das System bietet folgende Funktionen:"
        let detectedText = "Das System bietet folgende Funktionen:"
        let rewrittenText = "Das System umfasst die nachfolgenden Funktionen:"

        let proxy = FakeTextDocumentProxy(text: originalDocument)

        let outcome = TextReplacementEngine.apply(
            replacementText: rewrittenText,
            originalText: detectedText,
            textSource: .fallbackDetection,
            proxy: proxy
        ) { original, replacement in
            proxy.replaceLastOccurrence(of: original, with: replacement)
        }

        XCTAssertEqual(outcome, .replacedBySearch)
        XCTAssertEqual(
            proxy.text,
            "Wir planen die Entwicklung eines Systems für „Hansa MediCare“ zur Überwachung und Steuerung aller Aktivitäten im Bereich der Neukundengewinnung. Das System umfasst die nachfolgenden Funktionen:"
        )
        XCTAssertTrue(proxy.text.contains("Aktivitäten im Bereich der Neukundengewinnung."))
    }

    func testFallbackDetectionInsertsAtCursorWhenSearchMisses() {
        let proxy = FakeTextDocumentProxy(text: "prefix suffix", cursorOffset: 7)

        let outcome = TextReplacementEngine.apply(
            replacementText: "NEW",
            originalText: "missing",
            textSource: .fallbackDetection,
            proxy: proxy
        ) { _, _ in
            false
        }

        XCTAssertEqual(outcome, .insertedAtCursorFallback)
        XCTAssertEqual(proxy.text, "prefix NEWsuffix")
    }

    func testClipboardSourceAlwaysInsertsAtCursor() {
        let proxy = FakeTextDocumentProxy(text: "abc", cursorOffset: 1)
        var searchCalled = false

        let outcome = TextReplacementEngine.apply(
            replacementText: "X",
            originalText: "ignored",
            textSource: .clipboard,
            proxy: proxy
        ) { _, _ in
            searchCalled = true
            return true
        }

        XCTAssertFalse(searchCalled)
        XCTAssertEqual(outcome, .insertedAtCursorFallback)
        XCTAssertEqual(proxy.text, "aXbc")
    }
}

private final class FakeTextDocumentProxy: TextDocumentProxyEditing {
    private(set) var text: String
    private(set) var cursorOffset: Int
    private var selectionOffsets: Range<Int>?

    var selectedText: String? {
        guard let selectionOffsets else { return nil }
        return String(text[stringRange(from: selectionOffsets)])
    }

    init(
        text: String,
        cursorOffset: Int? = nil,
        selectionOffsets: Range<Int>? = nil
    ) {
        self.text = text
        self.cursorOffset = cursorOffset ?? text.count
        self.selectionOffsets = selectionOffsets
        if let selectionOffsets {
            self.cursorOffset = selectionOffsets.upperBound
        }
    }

    func selectFirstOccurrence(of substring: String) -> Bool {
        guard let range = text.range(of: substring) else { return false }
        let lower = text.distance(from: text.startIndex, to: range.lowerBound)
        let upper = text.distance(from: text.startIndex, to: range.upperBound)
        selectionOffsets = lower..<upper
        cursorOffset = upper
        return true
    }

    func insertText(_ inserted: String) {
        if let selectionOffsets {
            let range = stringRange(from: selectionOffsets)
            text.replaceSubrange(range, with: inserted)
            cursorOffset = selectionOffsets.lowerBound + inserted.count
            self.selectionOffsets = nil
            return
        }

        let insertionIndex = index(at: cursorOffset)
        text.insert(contentsOf: inserted, at: insertionIndex)
        cursorOffset += inserted.count
    }

    func deleteBackward() {
        if let selectionOffsets {
            let range = stringRange(from: selectionOffsets)
            text.removeSubrange(range)
            cursorOffset = selectionOffsets.lowerBound
            self.selectionOffsets = nil
            return
        }

        guard cursorOffset > 0 else { return }

        let start = index(at: cursorOffset - 1)
        let end = index(at: cursorOffset)
        text.removeSubrange(start..<end)
        cursorOffset -= 1
    }

    @discardableResult
    func replaceLastOccurrence(of original: String, with replacement: String) -> Bool {
        guard let range = text.range(of: original, options: .backwards) else { return false }
        let lower = text.distance(from: text.startIndex, to: range.lowerBound)
        text.replaceSubrange(range, with: replacement)
        cursorOffset = lower + replacement.count
        selectionOffsets = nil
        return true
    }

    private func stringRange(from offsets: Range<Int>) -> Range<String.Index> {
        let lower = index(at: offsets.lowerBound)
        let upper = index(at: offsets.upperBound)
        return lower..<upper
    }

    private func index(at offset: Int) -> String.Index {
        text.index(text.startIndex, offsetBy: offset)
    }
}
