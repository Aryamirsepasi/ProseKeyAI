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
                // Top bar - only show in toolList state
                if case .toolList = state {
                    HStack {
                        Spacer()
                        
                        // Show spinner if loading in toolList state
                        if isLoading {
                            ProgressView()
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 4)
                }
                
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
                
                // Text preview with fixed width and horizontal scrolling
                if let selectedText = vm.selectedText, !selectedText.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        Text(selectedText)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                    }
                    .frame(width: 180) // Fixed width
                    .background(Color(.systemGray6))
                    .cornerRadius(6)
                    .overlay(
                        // Visual indicator for scrollable content
                        HStack {
                            Spacer()
                            if selectedText.count > 20 {
                                LinearGradient(
                                    gradient: Gradient(colors: [.clear, Color(.systemGray6)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                .frame(width: 20)
                            }
                        }
                    )
                } else {
                    Text("No text selected")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .frame(width: 180) // Match width
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
        .onChange(of: vm.selectedText) { _ in
            // Force UI update when selected text changes
            // This helps ensure the preview updates properly
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
                
                // Loading indicator below text
                ProgressView()
                    .scaleEffect(1.2)
                    .padding(.top, 8)
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
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
            .padding(.top, 8)
            
            // Fixed height container for the result
            ZStack {
                // Background and border for the fixed-size container
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(.systemGray4), lineWidth: 1)
                
                // Background fill that matches the system gray
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray6))
                
                // ScrollView inside the fixed container
                ScrollView {
                    Markdown(aiResult)
                        .font(.body)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(1) // Small padding to prevent content touching the border
            }
            .frame(height: 160) // Fixed height for the result area
            
            HStack(spacing: 6) {
                // Copy button
                Button(action: {
                    UIPasteboard.general.string = aiResult
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
            .padding(.bottom, 4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .gesture(
            DragGesture()
                .onEnded { gesture in
                    if gesture.translation.height > 70 {
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

