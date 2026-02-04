import SwiftUI
import MarkdownUI
import UIKit

struct AIToolsView: View {
    @ObservedObject var vm: AIToolsViewModel
    
    // Keyboard height sized for 2 visible command rows
    private let keyboardHeight: CGFloat = KeyboardConstants.keyboardHeight

    @ScaledMetric(relativeTo: .body) private var actionButtonHeight: CGFloat = 40
    @ScaledMetric(relativeTo: .body) private var previewRowHeight: CGFloat = 32
    @ScaledMetric(relativeTo: .body) private var rowPadding: CGFloat = 8
    
    @State private var state: AIToolsUIState = .toolList
    @State private var isLoading = false
    @State private var aiResult: String = ""
    @State private var chosenCommand: KeyboardCommand? = nil
    @State private var customPrompt: String = ""
    @State private var activeTask: Task<Void, Never>?
    @State private var showFullAccessBanner = false

    @StateObject private var commandsManager = KeyboardCommandsManager()
    @ObservedObject private var clipboardManager = ClipboardHistoryManager.shared
    
    private var buttonRowHeight: CGFloat { min(actionButtonHeight + (rowPadding * 2), 72) }
    private var previewHeight: CGFloat { min(previewRowHeight + (rowPadding * 2), 64) }
    private var gridHeight: CGFloat { max(0, keyboardHeight - buttonRowHeight - previewHeight) }
    private var hasSelection: Bool { !(vm.selectedText?.isEmpty ?? true) }
    private var isGenerating: Bool {
        if case .generating = state { return true }
        return false
    }
    private var isBusy: Bool { isLoading || isGenerating }
    private var markdownFontSize: CGFloat {
        UIFont.preferredFont(forTextStyle: .body).pointSize
    }

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                switch state {
                case .toolList:
                    toolListView
                case .generating(let command):
                    generatingView(command)
                case .result(let command):
                    resultView(command)
                case .customPrompt:
                    customPromptView
                case .clipboardHistory:
                    clipboardHistoryView
                }
            }

            if showFullAccessBanner {
                FullAccessBannerView {
                    showFullAccessBanner = false
                }
                .padding(.top, 4)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .frame(height: keyboardHeight)
        .dynamicTypeSize(.xSmall ... .xxLarge)
        .errorBanner(error: $vm.currentError)
    }
    
    private var toolListView: some View {
        VStack(spacing: 0) {
            // Action buttons row — fixed 56 pt
            HStack(spacing: 6) {
                Button(action: {
                    guard vm.viewController?.hasFullAccess == true else {
                        showFullAccessWarning()
                        HapticsManager.shared.error()
                        vm.currentError = .generic("Full Access required")
                        return
                    }
                    HapticsManager.shared.keyPress()
                    vm.handleCopiedText()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.clipboard").font(.caption)
                        Text("Use Copied", comment: "Button: use the text currently on the clipboard")
                            .font(.footnote.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: actionButtonHeight)
                }
                .background(Color.blue, in: .rect(cornerRadius: 8))
                .foregroundStyle(.white)
                .buttonStyle(.plain)
                .disabled(isBusy)
                .accessibilityLabel("Use copied text")
                .accessibilityHint("Processes the text currently on your clipboard")
                
                Button(action: {
                    guard vm.viewController?.hasFullAccess == true else {
                        showFullAccessWarning()
                        HapticsManager.shared.error()
                        return
                    }
                    HapticsManager.shared.keyPress()
                    state = .clipboardHistory
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.arrow.circlepath").font(.caption)
                        Text("History", comment: "Button to view clipboard history")
                            .font(.footnote.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: actionButtonHeight)
                }
                .background(Color.orange, in: .rect(cornerRadius: 8))
                .foregroundStyle(.white)
                .buttonStyle(.plain)
                .disabled(isBusy)
                .accessibilityLabel("Clipboard history")
                .accessibilityHint("View and select from previously copied text")
                
                Button(action: {
                    guard hasSelection else {
                        HapticsManager.shared.error()
                        vm.currentError = .invalidSelection
                        return
                    }
                    HapticsManager.shared.keyPress()
                    customPrompt = ""
                    state = .customPrompt
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "magnifyingglass").font(.caption)
                        Text("Ask AI", comment: "Button to ask AI with custom prompt")
                            .font(.footnote.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: actionButtonHeight)
                }
                .background(hasSelection ? Color.purple : Color.gray, in: .rect(cornerRadius: 8))
                .foregroundStyle(.white)
                .buttonStyle(.plain)
                .disabled(!hasSelection || isBusy)
                .accessibilityLabel("Ask AI")
                .accessibilityHint("Enter a custom prompt to process the selected text")
            }
            .padding(.horizontal, 8)
            .padding(.top, rowPadding)
            .padding(.bottom, rowPadding)
            
            // Selected text preview — fixed 48 pt
            HStack(spacing: 6) {
                Group {
                    if let selectedText = vm.selectedText, !selectedText.isEmpty {
                        ScrollView(.horizontal) {
                            Text(selectedText)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 10)
                        }
                        .scrollIndicators(.hidden)
                    } else {
                        Text("No text selected")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                    }
                }
                .frame(height: previewRowHeight)
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6), in: .rect(cornerRadius: 6))

                Button(action: {
                    HapticsManager.shared.keyPress()
                    vm.checkSelectedText()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.blue)
                        .frame(width: previewRowHeight, height: previewRowHeight)
                        .background(Color(.systemGray6), in: .rect(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .disabled(isBusy)
                .accessibilityLabel("Refresh selection")
            }
            .padding(.horizontal, 8)
            .padding(.bottom, rowPadding)
            
            // Commands grid — now 152 pt to fit exactly 2 rows
            ScrollView(.vertical) {
                CommandsGridView(
                    commands: commandsManager.commands,
                    onCommandSelected: { cmd in
                        guard let text = vm.selectedText, !text.isEmpty else {
                            vm.currentError = .invalidSelection
                            return
                        }
                        isLoading = true
                        vm.clearError()
                        chosenCommand = cmd
                        state = .generating(cmd)
                        processAICommand(cmd, userText: text)
                    },
                    isDisabled: !hasSelection || isBusy
                )
                .padding(.horizontal, 8)
            }
            .scrollIndicators(.visible)
            .frame(height: gridHeight) // 152
        }
    }
    
    private var customPromptView: some View {
        CustomPromptView(
            selectedText: vm.selectedText ?? "",
            onSubmit: { prompt in
                guard let text = vm.selectedText, !text.isEmpty else {
                    vm.currentError = .invalidSelection
                    return
                }
                
                let command = KeyboardCommand(
                    name: "Custom Prompt",
                    prompt: prompt,
                    icon: "magnifyingglass"
                )
                
                isLoading = true
                vm.clearError()
                chosenCommand = command
                state = .generating(command)
                processAICommand(command, userText: text)
            },
            onCancel: {
                state = .toolList
                customPrompt = ""
            },
            prompt: $customPrompt
        )
    }
    
    private var clipboardHistoryView: some View {
        ClipboardHistoryView(
            manager: clipboardManager,
            viewController: vm.viewController,
            onDismiss: {
                state = .toolList
            }
        )
    }
    
    private func generatingView(_ command: KeyboardCommand) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Text("Applying \(command.displayName)...")
                .font(.headline)
                .accessibilityAddTraits(.updatesFrequently)
            ProgressView()
                .scaleEffect(1.2)
                .padding(.top, 8)
                .accessibilityLabel("Processing")
            Button("Cancel") {
                cancelActiveTask()
            }
            .buttonStyle(.bordered)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func resultView(_ command: KeyboardCommand) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("\(command.displayName) Result")
                    .font(.headline)
                Spacer()
                Button(action: {
                    state = .toolList
                    aiResult = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close result")
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)
            
            Spacer()
                .frame(height: 16)
            
            ScrollView {
                Markdown(aiResult)
                    .markdownTextStyle(\.text) { FontSize(markdownFontSize) }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 210)
            .background(Color(.systemGray6), in: .rect(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.separator), lineWidth: 0.5)
            )
            .padding(.horizontal, 12)
            
            Spacer()
                .frame(height: 16)
            
            HStack(spacing: 6) {
                Button(action: {
                    UIPasteboard.general.string = aiResult
                    HapticsManager.shared.success()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.doc").font(.footnote)
                        Text("Copy").font(.footnote.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(Color(.systemGray5), in: .rect(cornerRadius: 8))
                    .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    guard let text = vm.selectedText, let chosen = chosenCommand else { return }
                    HapticsManager.shared.keyPress()
                    isLoading = true
                    state = .generating(chosen)
                    aiResult = ""
                    processAICommand(chosen, userText: text)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise").font(.footnote)
                        Text("Retry").font(.footnote.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(Color.green, in: .rect(cornerRadius: 8))
                    .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Retry command")

                Button(action: {
                    replaceSelection(with: aiResult)
                    HapticsManager.shared.success()
                    state = .toolList
                    aiResult = ""
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "rectangle.and.pencil.and.ellipsis").font(.footnote)
                        Text("Replace").font(.footnote.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(Color.indigo, in: .rect(cornerRadius: 8))
                    .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Replace selected text")
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
    }
    
    private func processAICommand(
        _ command: KeyboardCommand,
        userText: String
    ) {
        activeTask?.cancel()
        
        activeTask = Task(priority: .userInitiated) {
            do {
                try Task.checkCancellation()
                let truncated = userText.count > 8000
                ? String(userText.prefix(8000))
                : userText
                let result = try await AppState.shared.activeProvider.processText(
                    systemPrompt: command.prompt,
                    userPrompt: truncated,
                    images: [],
                    streaming: false
                )
                
                try Task.checkCancellation()
                
                await MainActor.run {
                    aiResult = result
                    isLoading = false
                    state = .result(command)
                    vm.clearError()
                    HapticsManager.shared.success()
                }
            } catch is CancellationError {
                await MainActor.run { isLoading = false }
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    vm.setError(error)
                    isLoading = false
                    state = .toolList
                    chosenCommand = nil
                    HapticsManager.shared.error()
                }
            }
        }
    }

    private func cancelActiveTask() {
        activeTask?.cancel()
        activeTask = nil
        isLoading = false
        aiResult = ""
        chosenCommand = nil
        state = .toolList
    }

    private func replaceSelection(with text: String) {
        guard let proxy = vm.viewController?.textDocumentProxy else { return }
        guard let selected = vm.selectedText, !selected.isEmpty else {
            proxy.insertText(text)
            return
        }
        
        // Check if there's actual selected text (iOS 16+)
        if #available(iOS 16.0, *), let actualSelection = proxy.selectedText, !actualSelection.isEmpty {
            // Text is truly selected - deleteBackward will remove the selection
            // Use UTF-16 count for accurate deletion since UIKit uses UTF-16 internally
            for _ in 0..<actualSelection.utf16.count {
                proxy.deleteBackward()
            }
        } else {
            // Fallback: text was combined from before+after cursor context
            // We need to delete both before and after the cursor
            let before = proxy.documentContextBeforeInput ?? ""
            let after = proxy.documentContextAfterInput ?? ""
            
            // Delete text after cursor first (move forward then delete backward)
            // We need to move cursor to end of "after" text, then delete backward
            if !after.isEmpty {
                // Adjust cursor position to end of after text
                proxy.adjustTextPosition(byCharacterOffset: after.utf16.count)
                // Now delete the after portion
                for _ in 0..<after.utf16.count {
                    proxy.deleteBackward()
                }
            }
            
            // Delete text before cursor
            if !before.isEmpty {
                for _ in 0..<before.utf16.count {
                    proxy.deleteBackward()
                }
            }
        }
        
        proxy.insertText(text)
    }

    private func showFullAccessWarning() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            showFullAccessBanner = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeOut(duration: 0.2)) {
                showFullAccessBanner = false
            }
        }
    }
}

private struct FullAccessBannerView: View {
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "lock.fill")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white)
            Text("Full Access required for clipboard tools")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
            Spacer(minLength: 4)
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.85))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss full access notice")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.red, in: Capsule())
        .frame(maxWidth: 300)
        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
        .accessibilityElement(children: .combine)
        .onAppear {
            UIAccessibility.post(notification: .announcement, argument: "Full Access required for clipboard tools")
        }
    }
}

enum AIToolsUIState {
    case toolList
    case generating(KeyboardCommand)
    case result(KeyboardCommand)
    case customPrompt
    case clipboardHistory
}
