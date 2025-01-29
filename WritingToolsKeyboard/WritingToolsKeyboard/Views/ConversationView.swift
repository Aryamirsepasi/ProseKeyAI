import SwiftUI
import MarkdownUI

struct ConversationView: View {
    @EnvironmentObject var llm: LocalLLMProvider
    @EnvironmentObject var appManager: AppManager
    let thread: Thread
    let generatingThreadID: UUID?
    
    @State private var scrollID: String?
    @State private var scrollInterrupted = false
    
    var body: some View {
        ScrollViewReader { scrollView in
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(thread.sortedMessages) { message in
                        MessageView(message: message)
                            .padding()
                            .id(message.id.uuidString)
                    }
                    
                    // If local LLM is streaming tokens for this thread
                    if llm.running && !llm.output.isEmpty && thread.id == generatingThreadID {
                        VStack {
                            MessageView(message: Message(role: .assistant, content: llm.output + " ⌛️"))
                        }
                        .padding()
                        .id("output")
                        .onAppear {
                            scrollInterrupted = false
                        }
                    }
                    
                    Rectangle()
                        .fill(.clear)
                        .frame(height: 1)
                        .id("bottom")
                }
                .scrollTargetLayout()
            }
            .scrollPosition(id: $scrollID, anchor: .bottom)
            .onChange(of: llm.output) { _, _ in
                if !scrollInterrupted {
                    scrollView.scrollTo("bottom")
                }
                if !llm.isProcessing {
                    appManager.playHaptic()
                }
            }
            .onChange(of: scrollID) { _, _ in
                if llm.running {
                    scrollInterrupted = true
                }
            }
        }
        .defaultScrollAnchor(.bottom)
        .scrollDismissesKeyboard(.interactively)
    }
}

struct MessageView: View {
    @EnvironmentObject var llm: LocalLLMProvider
    let message: Message
    @State private var collapsed = true
    
    var time: String {
        let totalTime = message.generatingTime ?? 0
        return totalTime.formatted
    }
    
    var body: some View {
        HStack {
            if message.role == .user { Spacer() }
            
            if message.role == .assistant {
                VStack(alignment: .leading, spacing: 16) {
                    Markdown(message.content)
                        .textSelection(.enabled)
                        .padding(.trailing, 48)
                }
            } else {
                Markdown(message.content)
                    .textSelection(.enabled)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .mask(RoundedRectangle(cornerRadius: 24))
                    .padding(.leading, 48)
            }
            
            if message.role == .assistant { Spacer() }
        }
        .onAppear {
            if llm.running {
                collapsed = false
            }
        }
    }
}

extension TimeInterval {
    var formatted: String {
        let totalSeconds = Int(self)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        
        if minutes > 0 {
            return seconds > 0 ? "\(minutes)m \(seconds)s" : "\(minutes)m"
        } else {
            return "\(seconds)"
        }
    }
}
