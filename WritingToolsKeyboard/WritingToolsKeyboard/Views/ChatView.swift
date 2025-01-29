import SwiftUI
import SwiftData
import MarkdownUI

struct ChatView: View {
    @EnvironmentObject var appManager: AppManager
    @Environment(\.modelContext) var modelContext
    @Binding var currentThread: Thread?
    @EnvironmentObject var llm: LocalLLMProvider
    @Namespace var bottomID
    @State var showModelPicker = false
    @State var prompt = ""
    @FocusState.Binding var isPromptFocused: Bool
    @Binding var showChats: Bool
    @Binding var showSettings: Bool
    
    @State var thinkingTime: TimeInterval?
    @State private var generatingThreadID: UUID?
    
    @AppStorage("current_provider") private var currentProvider = "local"
    @EnvironmentObject var appState: AppState
    
    var isPromptEmpty: Bool {
        prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var chatInput: some View {
        HStack(alignment: .bottom, spacing: 0) {
            TextField("Message", text: $prompt, axis: .vertical)
                .focused($isPromptFocused)
                .textFieldStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .frame(minHeight: 48)
                .onSubmit {
                    isPromptFocused = true
                    generate()
                }
            
            if llm.running {
                stopButton
            } else {
                generateButton
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }
    
    var generateButton: some View {
        Button {
            generate()
        } label: {
            Image(systemName: "arrow.up.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
        }
        .disabled(isPromptEmpty)
        .padding(.trailing, 12)
        .padding(.bottom, 12)
    }
    
    var stopButton: some View {
        Button {
            llm.stop()
        } label: {
            Image(systemName: "stop.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
        }
        .disabled(llm.cancelled)
        .padding(.trailing, 12)
        .padding(.bottom, 12)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let currentThread = currentThread {
                    ConversationView(thread: currentThread, generatingThreadID: generatingThreadID)
                } else {
                    Spacer()
                    Image(systemName: "bubble.left.and.bubble.right")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32, height: 32)
                        .foregroundStyle(.quaternary)
                    Spacer()
                }
                
                // Dismiss keyboard button above input
                HStack {
                    Spacer()
                    Button {
                        isPromptFocused = false
                    } label: {
                        Image(systemName: "chevron.down.circle.fill")
                            .font(.system(size: 28))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundColor(.secondary)
                    }
                    .padding(.trailing, 16)
                    .padding(.bottom, 8)
                }
                
                HStack(alignment: .bottom) {
                    chatInput
                }
                .padding()
            }
            .navigationTitle(currentThread?.title ?? "Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if appManager.userInterfaceIdiom == .phone {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(action: {
                            appManager.playHaptic()
                            showChats.toggle()
                        }) {
                            Image(systemName: "list.bullet")
                        }
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        appManager.playHaptic()
                        showSettings.toggle()
                    }) {
                        Image(systemName: "gear")
                    }
                }
            }
        }
    }
    
    private func generate() {
        if !isPromptEmpty {
            if currentThread == nil {
                let newThread = Thread()
                currentThread = newThread
                modelContext.insert(newThread)
                try? modelContext.save()
            }
            
            if let currentThread = currentThread {
                generatingThreadID = currentThread.id
                Task {
                    let message = prompt
                    prompt = ""
                    appManager.playHaptic()
                    sendMessage(Message(role: .user, content: message, thread: currentThread))
                    isPromptFocused = true
                    
                    let output = await ChatMessageHandler.processMessage(
                        content: message,
                        thread: currentThread,
                        appState: appState,
                        llm: llm,
                        appManager: appManager,
                        currentProvider: currentProvider
                    )
                    
                    sendMessage(Message(role: .assistant, content: output, thread: currentThread, generatingTime: llm.isProcessing ? 1.0 : nil))
                    generatingThreadID = nil
                }
            }
        }
    }
    
    private func sendMessage(_ message: Message) {
        appManager.playHaptic()
        modelContext.insert(message)
        try? modelContext.save()
    }
}
