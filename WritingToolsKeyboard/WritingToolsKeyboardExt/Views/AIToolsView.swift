import SwiftUI
import MarkdownUI

struct AIToolsView: View {
    @ObservedObject var vm: AIToolsViewModel
    
    // The local UI state: either showing the tool list, or generating, or viewing a result.
    @State private var state: AIToolsUIState = .toolList
    @State private var isLoading = false
    @State private var aiResult: String = ""
    private let minKeyboardHeight: CGFloat = 240
    @State private var chosenCommand: KeyboardCommand? = nil
    
    @StateObject private var commandsManager = KeyboardCommandsManager()
    
    var body: some View {
        VStack(spacing: 12) {
            // Top bar
            HStack {
                if case .toolList = state {
                    // Empty in toolList state
                } else {
                    Button(action: {
                        state = .toolList
                        aiResult = ""
                        isLoading = false
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20))
                    }
                }
                
                Spacer()
                
                // Show spinner if loading
                if isLoading {
                    ProgressView()
                }
            }
            .padding(.horizontal)
            .padding(.top, 4)
            
            if let error = vm.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            switch state {
            case .toolList:
                toolListView
            case .generating(let command):
                generatingView(command)
            case .result(let command):
                resultView(command)
            }
        }
        .frame(minHeight: minKeyboardHeight) // Set the minimum height for the keyboard
    }
    
    private var toolListView: some View {
        VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Button(action: {
                        vm.handleCopiedText()
                    }) {
                        HStack {
                            Image(systemName: "doc.on.clipboard")
                                .font(.system(size: 16))
                            Text("Use Copied Text")
                                .font(.system(size: 15, weight: .medium))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Text preview with better visual distinction
                    if let selectedText = vm.selectedText {
                        ScrollView(.horizontal, showsIndicators: false) {
                            Text(selectedText.count > 22 ? String(selectedText.prefix(22)) + "..." : selectedText)
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 10)
                                .background(Color(.systemGray6))
                                .cornerRadius(6)
                        }
                    } else {
                        Text("No text selected")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(Color(.systemGray6))
                            .cornerRadius(6)
                    }
                }
            .padding(.horizontal)
            
            ScrollView {
                        allCommandsView
                            .padding(.horizontal)
                    }
        }
    }
    
    var allCommandsView: some View {
        CommandsGridView(
            commands: commandsManager.commands,
            onCommandSelected: { command in
                guard let text = vm.selectedText, !text.isEmpty else {
                    vm.errorMessage = "No text is selected."
                    return
                }
                isLoading = true
                vm.errorMessage = nil
                chosenCommand = command
                state = .generating(command)
                processAICommand(command, userText: text)
            },
            isDisabled: vm.selectedText == nil || vm.selectedText!.isEmpty
        )
    }
    
    private func generatingView(_ command: KeyboardCommand) -> some View {
        VStack(spacing: 16) {
            Text("Applying \(command.name)...")
                .font(.headline)
                .padding(.top, 20)
            
            Spacer()
        }
    }
    
    private func resultView(_ command: KeyboardCommand) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("\(command.name) Result")
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
            
            ScrollView {
                Markdown(aiResult)
                    .font(.body)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .frame(maxWidth: .infinity, alignment: .leading)

            }
            
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
            
            HStack(spacing: 6) {
                // Copy button
                Button(action: {
                    UIPasteboard.general.string = aiResult
                    // Show success feedback
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }) {
                    HStack {
                        Image(systemName: "doc.on.doc")
                        Text("Copy")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray5))
                    .foregroundColor(.primary)
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Insert button
                Button(action: {
                    vm.viewController?.textDocumentProxy.insertText(aiResult)
                    state = .toolList
                    aiResult = ""
                }) {
                    HStack {
                        Image(systemName: "text.insert")
                        Text("Insert")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Regenerate button
                Button(action: {
                    guard let text = vm.selectedText, let chosen = chosenCommand else { return }
                    isLoading = true
                    state = .generating(chosen)
                    aiResult = ""
                    processAICommand(chosen, userText: text)
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Regenerate")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.bottom, 12)
        // Add swipe down gesture to dismiss
        .gesture(
            DragGesture()
                .onEnded { gesture in
                    if gesture.translation.height > 100 {
                        state = .toolList
                        aiResult = ""
                    }
                }
        )
    }
    
    // MARK: - Logic for calling AI
    private func processAICommand(_ command: KeyboardCommand, userText: String) {
        Task(priority: .userInitiated) {
            do {
                // Truncate text early to avoid unnecessary memory allocation
                let truncatedText = userText.count > 8000 ? String(userText.prefix(8000)) : userText
                let result = try await AppState.shared.activeProvider.processText(
                    systemPrompt: command.prompt,
                    userPrompt: truncatedText,
                    images: [],
                    streaming: false
                )
                await MainActor.run {
                    aiResult = result
                    isLoading = false
                    state = .result(command)
                    vm.errorMessage = nil
                }
            } catch {
                await MainActor.run {
                    vm.errorMessage = error.localizedDescription
                    isLoading = false
                    state = .toolList
                    chosenCommand = nil
                }
            }
        }
    }
}

// A small UI enum to track the sub-screen
enum AIToolsUIState {
    case toolList
    case generating(KeyboardCommand)
    case result(KeyboardCommand)
}

