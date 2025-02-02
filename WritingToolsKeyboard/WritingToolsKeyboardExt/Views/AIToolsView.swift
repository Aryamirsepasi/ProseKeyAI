import SwiftUI

struct AIToolsView: View {
    @ObservedObject var vm: AIToolsViewModel
    
    // The local UI state: either showing the tool list, or generating, or viewing a result.
    @State private var state: AIToolsUIState = .toolList
    @State private var isLoading = false
    @State private var aiResult: String = ""
    @State private var chosenOption: WritingOption? = nil
    
    @StateObject private var commandsManager = CustomCommandsManager()
    
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
            case .generating(let option):
                generatingView(option)
            case .result(let option):
                resultView(option)
            }
        }
    }
    
    private var toolListView: some View {
        VStack(spacing: 10) {
            
            // 1) Use Copied Text
            Button("Use Copied Text") {
                vm.handleCopiedText()
            }
            .buttonStyle(.bordered)
            .scaleEffect(0.9)
            
            let truncated = vm.selectedText.map {
                $0.count > 50 ? String($0.prefix(50)) + "..." : $0
            } ?? "None"
            
            Text("Current Text: \(truncated)")
                .font(.footnote)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.tail)
            
            // 2) AI Tools Grid
            ScrollView {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 80))],
                    
                    spacing: 8
                ) {
                    builtInTools
                    customTools
                    
                }
            }.padding(.horizontal)
            
        }
    }
    
    var builtInTools: some View {
        ForEach(WritingOption.allCases, id: \.self) { option in
            AIOptionButton(option: option) {
                guard let text = vm.selectedText, !text.isEmpty else {
                    vm.errorMessage = "No text is selected."
                    return
                }
                isLoading = true
                vm.errorMessage = nil
                chosenOption = option
                state = .generating(option)
                processAIOption(option, userText: text)
            }
            .disabled(vm.selectedText == nil || vm.selectedText!.isEmpty)
        }
    }
    var customTools: some View {
        CustomToolsGridView(commands: commandsManager.commands) { cmd in
            guard let text = vm.selectedText, !text.isEmpty else {
                vm.errorMessage = "No text is selected."
                return
            }
            isLoading = true
            chosenOption = nil
            vm.errorMessage = nil
            state = .generating(.rewrite)
            processAIOption(customPrompt: cmd.prompt, userText: text)
        }
        .disabled((UIPasteboard.general.string ?? "").isEmpty)
        
    }
    
    private func generatingView(_ option: WritingOption) -> some View {
        VStack(spacing: 16) {
            Text("Applying \(option.rawValue)...")
                .font(.headline)
                .padding(.top, 20)
            
            Spacer()
        }
    }
    
    private func resultView(_ option: WritingOption) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(option.rawValue) Result")
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
                    guard let text = vm.selectedText, let chosen = chosenOption else { return }
                    isLoading = true
                    state = .generating(chosen)
                    aiResult = ""
                    processAIOption(chosen, userText: text)
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
    // For built-in tools
    private func processAIOption(_ option: WritingOption, userText: String) {
        Task {
            do {
                let truncatedText = userText.count > 8000 ? String(userText.prefix(8000)) : userText
                let result = try await AppState.shared.activeProvider.processText(
                    systemPrompt: option.systemPrompt,
                    userPrompt: truncatedText,
                    images: [],
                    streaming: false
                )
                await MainActor.run {
                    aiResult = result
                    isLoading = false
                    state = .result(option)
                    vm.errorMessage = nil
                }
            } catch {
                await MainActor.run {
                    vm.errorMessage = error.localizedDescription
                    isLoading = false
                    state = .toolList
                    chosenOption = nil
                }
            }
        }
    }
    
    // For custom commands
    private func processAIOption(customPrompt: String, userText: String) {
        Task {
            do {
                let truncatedText = userText.count > 8000 ? String(userText.prefix(8000)) : userText
                let result = try await AppState.shared.activeProvider.processText(
                    systemPrompt: customPrompt,
                    userPrompt: truncatedText,
                    images: [],
                    streaming: false
                )
                await MainActor.run {
                    aiResult = result
                    isLoading = false
                    state = .result(.rewrite)
                    vm.errorMessage = nil
                }
            } catch {
                await MainActor.run {
                    vm.errorMessage = error.localizedDescription
                    isLoading = false
                    state = .toolList
                    chosenOption = nil
                }
            }
        }
    }
}

// A small UI enum to track the sub-screen
enum AIToolsUIState {
    case toolList
    case generating(WritingOption)
    case result(WritingOption)
}
