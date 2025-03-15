import SwiftUI

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
        VStack(spacing: 10) {
            // Cache and reuse views
            let previewText = vm.selectedText.map {
                $0.count > 50 ? String($0.prefix(50)) + "..." : $0
            } ?? "None"
            
            HStack(spacing: 12) {
                Button("Use Copied Text") {
                    vm.handleCopiedText()
                }
                .buttonStyle(.bordered)
                .scaleEffect(0.9)
                
                // Use Text only when needed
                Text(previewText)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal)
            
            ScrollView {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 80))],
                    spacing: 8
                ) {
                    allCommandsView
                }
            }.padding(.horizontal)
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
        VStack(alignment: .leading, spacing: 12) {
            Text("\(command.name) Result")
                .font(.headline)
            
            ScrollView {
                Text(aiResult)
                    .font(.body)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .frame(maxHeight: 200)
            }
            
            HStack {
                Button("Copy") {
                    UIPasteboard.general.string = aiResult
                }
                .buttonStyle(.bordered)
                
                Button("Regenerate") {
                    guard let text = vm.selectedText, let chosen = chosenCommand else { return }
                    isLoading = true
                    state = .generating(chosen)
                    aiResult = ""
                    processAICommand(chosen, userText: text)
                }
                .buttonStyle(.borderedProminent)
                
                Spacer()
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.bottom, 12)
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

