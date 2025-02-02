import SwiftUI
import MarkdownUI

// MARK: - Conversation View

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
                            .padding(.vertical, 4)
                            .id(message.id.uuidString)
                    }
                    
                    // If local LLM is streaming tokens for this thread
                    if llm.running && !llm.output.isEmpty && thread.id == generatingThreadID {
                        MessageView(message: Message(role: .assistant, content: llm.output + " ⌛️"))
                            .padding(.vertical, 4)
                            .id("output")
                            .onAppear { scrollInterrupted = false }
                    }
                    
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 1)
                        .id("bottom")
                }
                .scrollTargetLayout()
            }
            .scrollPosition(id: $scrollID, anchor: .bottom)
            .onChange(of: llm.output) { _, _ in
                if !scrollInterrupted { scrollView.scrollTo("bottom") }
                if !llm.isProcessing { appManager.playHaptic() }
            }
            .onChange(of: scrollID) { _, _ in
                if llm.running { scrollInterrupted = true }
            }
        }
        .defaultScrollAnchor(.bottom)
        .scrollDismissesKeyboard(.interactively)
    }
}

// MARK: - Message View

struct MessageView: View {
    let message: Message
    
    // Determine if this message is from the user.
    var isUser: Bool { message.role == .user }
    
    // Bubble colors:
    // - For user messages: Blue bubble.
    // - For assistant messages: Dark gray bubble.
    var bubbleColor: Color {
        isUser ? Color.blue : Color(UIColor.darkGray)
    }
    
    // Both texts are white.
    var textColor: Color { .white }
    
    // Format the timestamp (using only the time portion).
    var timeText: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: message.timestamp)
    }
    
    var body: some View {
        VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
            HStack {
                // For user messages, add a spacer before the bubble (pushes bubble to right)
                if isUser { Spacer(minLength: 40) }
                
                Markdown(message.content)
                    .font(.body)
                    .foregroundColor(textColor)
                    .padding(12)
                    .background(
                        ChatBubble(isUser: isUser)
                            .fill(bubbleColor)
                    )
                    .contextMenu {
                        Button("Copy") {
                            UIPasteboard.general.string = message.content
                        }
                    }
                
                // For assistant messages, add a spacer after the bubble (pushes bubble to left)
                if !isUser { Spacer(minLength: 40) }
            }
            .padding(.horizontal, 16)
            
            // Timestamp below the bubble.
            HStack {
                if isUser { Spacer() }
                Text(timeText)
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .padding(isUser ? .trailing : .leading, 0)
                if !isUser { Spacer() }
            }
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - ChatBubble Shape (No Tail, Modified Corner Radii)

struct ChatBubble: Shape {
    var isUser: Bool
    
    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 16
        var path = Path()
        
        if isUser {
            // For user messages:
            // Rounded corners: top-left, top-right, bottom-left.
            // Bottom-right: square.
            
            // Start at top-left corner (offset by radius)
            path.move(to: CGPoint(x: rect.minX + radius, y: rect.minY))
            // Top edge
            path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
            // Top-right arc
            path.addArc(center: CGPoint(x: rect.maxX - radius, y: rect.minY + radius),
                        radius: radius,
                        startAngle: Angle(degrees: -90),
                        endAngle: Angle(degrees: 0),
                        clockwise: false)
            // Right edge straight down (no rounding at bottom-right)
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            // Bottom edge: from bottom-right to bottom-left + radius
            path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
            // Bottom-left arc
            path.addArc(center: CGPoint(x: rect.minX + radius, y: rect.maxY - radius),
                        radius: radius,
                        startAngle: Angle(degrees: 90),
                        endAngle: Angle(degrees: 180),
                        clockwise: false)
            // Left edge
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
            // Top-left arc
            path.addArc(center: CGPoint(x: rect.minX + radius, y: rect.minY + radius),
                        radius: radius,
                        startAngle: Angle(degrees: 180),
                        endAngle: Angle(degrees: 270),
                        clockwise: false)
            path.closeSubpath()
        } else {
            // For assistant messages:
            // Rounded corners: top-left, top-right, bottom-right.
            // Bottom-left: square.
            
            // Start at top-left corner
            path.move(to: CGPoint(x: rect.minX + radius, y: rect.minY))
            // Top edge
            path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
            // Top-right arc
            path.addArc(center: CGPoint(x: rect.maxX - radius, y: rect.minY + radius),
                        radius: radius,
                        startAngle: Angle(degrees: -90),
                        endAngle: Angle(degrees: 0),
                        clockwise: false)
            // Right edge
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
            // Bottom-right arc
            path.addArc(center: CGPoint(x: rect.maxX - radius, y: rect.maxY - radius),
                        radius: radius,
                        startAngle: Angle(degrees: 0),
                        endAngle: Angle(degrees: 90),
                        clockwise: false)
            // Bottom edge: go straight to the left (no rounding at bottom-left)
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            // Left edge
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
            // Top-left arc
            path.addArc(center: CGPoint(x: rect.minX + radius, y: rect.minY + radius),
                        radius: radius,
                        startAngle: Angle(degrees: 180),
                        endAngle: Angle(degrees: 270),
                        clockwise: false)
            path.closeSubpath()
        }
        return path
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
            return "\(seconds)s"
        }
    }
}
