import SwiftUI

struct AIToolsView: View {
    @Binding var selectedText: String?
    let onDismiss: () -> Void
    
    // The local UI state: either showing the tool list, or generating, or viewing a result.
    @State private var state: AIToolsUIState = .toolList
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var aiResult: String = ""
    @State private var chosenOption: WritingOption? = nil
    
    @StateObject private var commandsManager = CustomCommandsManager()
    
    var body: some View {
        VStack(spacing: 12) {
            // Top bar
            HStack {
                Button(action: {
                    switch state {
                    case .toolList:
                        onDismiss()
                    case .generating(_), .result(_):
                        state = .toolList
                        aiResult = ""
                        isLoading = false
                    }
                }) {
                    Image(systemName: "keyboard")
                        .font(.system(size: 20))
                }
                
                Spacer()
                
                // Show spinner if loading
                if isLoading {
                    ProgressView()
                }
            }
            .padding(.horizontal)
            .padding(.top, 4)
            
            if let error = errorMessage {
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
}

// MARK: - Subviews / UI States

extension AIToolsView {
    
    private var toolListView: some View {
        VStack(spacing: 10) {
            
            // 1) Use Copied Text
            Button("Use Copied Text") {
                let clipboardText = UIPasteboard.general.string ?? ""
                if clipboardText.isEmpty {
                    errorMessage = "No text in clipboard"
                } else {
                    selectedText = clipboardText
                    errorMessage = nil
                }
            }
            .buttonStyle(.bordered)
            .scaleEffect(0.9)
            .disabled((UIPasteboard.general.string ?? "").isEmpty)
            
            let truncated = selectedText.map {
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
                    columns: [
                        GridItem(.flexible(minimum: 60)),
                        GridItem(.flexible(minimum: 60)),
                        GridItem(.flexible(minimum: 60)),
                        GridItem(.flexible(minimum: 60))
                    ],
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
                guard let text = selectedText, !text.isEmpty else {
                    errorMessage = "No text is selected."
                    return
                }
                isLoading = true
                errorMessage = nil
                chosenOption = option
                state = .generating(option)
                processAIOption(option, userText: text)
            }
            .disabled(selectedText == nil || selectedText!.isEmpty)
        }
    }
    var customTools: some View {
        CustomToolsGridView(commands: commandsManager.commands) { cmd in
            guard let text = selectedText, !text.isEmpty else {
                errorMessage = "No text is selected."
                return
            }
            isLoading = true
            chosenOption = nil
            errorMessage = nil
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
                    guard let text = selectedText, let chosen = chosenOption else { return }
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
                    userPrompt: truncatedText
                )
                await MainActor.run {
                    aiResult = result
                    isLoading = false
                    state = .result(option)
                    errorMessage = nil
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
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
                    userPrompt: truncatedText
                )
                await MainActor.run {
                    aiResult = result
                    isLoading = false
                    state = .result(.rewrite)
                    errorMessage = nil
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
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
