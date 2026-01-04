import SwiftUI
import MarkdownUI

struct AIToolsView: View {
    @ObservedObject var vm: AIToolsViewModel
    
    // Keyboard height sized for 2 visible command rows
    private let keyboardHeight: CGFloat = KeyboardConstants.keyboardHeight
    private let buttonRowHeight: CGFloat = 56   // (40 button + padding)
    private let previewHeight: CGFloat = 48     // (32 text + padding)
    
    @State private var state: AIToolsUIState = .toolList
    @State private var isLoading = false
    @State private var aiResult: String = ""
    @State private var chosenCommand: KeyboardCommand? = nil
    @State private var customPrompt: String = ""
    @State private var activeTask: Task<Void, Never>?

    @StateObject private var commandsManager = KeyboardCommandsManager()
    @ObservedObject private var clipboardManager = ClipboardHistoryManager.shared
    
    private var gridHeight: CGFloat { keyboardHeight - buttonRowHeight - previewHeight }

    var body: some View {
        ZStack {
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
        }
        .frame(height: keyboardHeight)
        .errorBanner(error: $vm.currentError)
    }
    
    private var toolListView: some View {
        VStack(spacing: 0) {
            // Action buttons row — fixed 56 pt
            HStack(spacing: 6) {
                Button(action: {
                    HapticsManager.shared.keyPress()
                    vm.handleCopiedText()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.clipboard").font(.system(size: 14))
                        Text("Use Copied", comment: "Button: use the text currently on the clipboard")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                }
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    HapticsManager.shared.keyPress()
                    state = .clipboardHistory
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.arrow.circlepath").font(.system(size: 14))
                        Text("History", comment: "Button to view clipboard history")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                }
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(8)
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    guard vm.selectedText != nil && !vm.selectedText!.isEmpty else {
                        HapticsManager.shared.error()
                        vm.currentError = .invalidSelection
                        return
                    }
                    HapticsManager.shared.keyPress()
                    customPrompt = ""
                    state = .customPrompt
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "magnifyingglass").font(.system(size: 14))
                        Text("Ask AI", comment: "Button to ask AI with custom prompt")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                }
                .background(vm.selectedText?.isEmpty != false ? Color.gray : Color.purple)
                .foregroundColor(.white)
                .cornerRadius(8)
                .buttonStyle(PlainButtonStyle())
                .disabled(vm.selectedText?.isEmpty != false)
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
            .padding(.bottom, 8)
            
            // Selected text preview — fixed 48 pt
            Group {
                if let selectedText = vm.selectedText, !selectedText.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        Text(selectedText)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                    }
                    .frame(height: 32)
                    .background(Color(.systemGray6))
                    .cornerRadius(6)
                } else {
                    Text("No text selected")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .frame(height: 32)
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray6))
                        .cornerRadius(6)
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
            
            // Commands grid — now 152 pt to fit exactly 2 rows
            ScrollView(.vertical, showsIndicators: true) {
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
                    isDisabled: vm.selectedText == nil || vm.selectedText!.isEmpty
                )
                .padding(.horizontal, 8)
            }
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
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)
            
            Spacer()
                .frame(height: 16)
            
            ScrollView {
                Markdown(aiResult)
                    .markdownTextStyle(\.text) { FontSize(14) }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 210)
            .background(Color(.systemGray6))
            .cornerRadius(8)
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
                        Image(systemName: "doc.on.doc").font(.system(size: 13))
                        Text("Copy").font(.system(size: 13, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(Color(.systemGray5))
                    .foregroundColor(.primary)
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                
                
                Button(action: {
                    HapticsManager.shared.success()
                    vm.viewController?.textDocumentProxy.insertText(aiResult)
                    state = .toolList
                    aiResult = ""
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "text.insert").font(.system(size: 13))
                        Text("Insert").font(.system(size: 13, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    guard let text = vm.selectedText, let chosen = chosenCommand else { return }
                    HapticsManager.shared.keyPress()
                    isLoading = true
                    state = .generating(chosen)
                    aiResult = ""
                    processAICommand(chosen, userText: text)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise").font(.system(size: 13))
                        Text("Retry").font(.system(size: 13, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
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
                let truncated = userText.count > 8000
                ? String(userText.prefix(8000))
                : userText
                let result = try await AppState.shared.activeProvider.processText(
                    systemPrompt: command.prompt,
                    userPrompt: truncated,
                    images: [],
                    streaming: false
                )
                
                guard !Task.isCancelled else {
                    await MainActor.run { isLoading = false }
                    return
                }
                
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
}

enum AIToolsUIState {
    case toolList
    case generating(KeyboardCommand)
    case result(KeyboardCommand)
    case customPrompt
    case clipboardHistory
}
