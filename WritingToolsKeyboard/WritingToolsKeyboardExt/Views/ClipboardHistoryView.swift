import SwiftUI

struct ClipboardHistoryView: View {
    @ObservedObject var manager: ClipboardHistoryManager
    weak var viewController: KeyboardViewController?
    let onDismiss: () -> Void
    
    @State private var copiedItemId: UUID?
    
    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]
    
    var body: some View {
        let items = manager.nonExpiredItems
        VStack(spacing: 0) {
            // Header - 45pt (44 frame + 1 divider)
            headerView(hasItems: !items.isEmpty)
            Divider()

            // Content
            if items.isEmpty {
                emptyStateView
            } else {
                clipboardGridView(items: items)
            }
        }
    }
    
    private func headerView(hasItems: Bool) -> some View {
        HStack {
            Button(action: {
                HapticsManager.shared.keyPress()
                onDismiss()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 17))
                }
                .foregroundColor(.blue)
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            Text("Clipboard History")
                .font(.system(size: 17, weight: .semibold))
            
            Spacer()
            
            if hasItems {
                Button(action: {
                    HapticsManager.shared.keyPress()
                    manager.clearAll()
                }) {
                    Text("Clear")
                        .font(.system(size: 17))
                        .foregroundColor(.red)
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                Text("Clear")
                    .font(.system(size: 17))
                    .foregroundColor(.clear)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(height: 44)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Spacer()

            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No Clipboard History")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.primary)

            Text("Copy text to see it appear here")
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private func clipboardGridView(items: [ClipboardItem]) -> some View {
        ScrollView(.vertical, showsIndicators: true) {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(items) { item in
                    ClipboardItemCard(
                        item: item,
                        isCopied: copiedItemId == item.id,
                        onTap: { handleItemTap(item) },
                        onDelete: { manager.deleteItem(item) }
                    )
                }
            }
            .padding(12)
        }
        .frame(maxHeight: .infinity)
    }
    
    private func handleItemTap(_ item: ClipboardItem) {
        manager.copyItem(item)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            copiedItemId = item.id
        }
        viewController?.textDocumentProxy.insertText(item.content)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation { copiedItemId = nil }
            onDismiss()
        }
    }
}

private struct ClipboardCardStyle: ButtonStyle {
    let isCopied: Bool
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(12)
            .frame(height: 100)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isCopied ? Color.green.opacity(0.1) : Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isCopied ? Color.green.opacity(0.5) : Color(.separator), lineWidth: isCopied ? 2 : 0.5)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .contentShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ClipboardItemCard: View {
    let item: ClipboardItem
    let isCopied: Bool
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: onTap) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(item.displayText)
                        .font(.system(size: 14))
                        .foregroundColor(.primary)
                        .lineLimit(4)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Spacer()
                    
                    HStack {
                        Image(systemName: isCopied ? "checkmark.circle.fill" : "doc.on.doc")
                            .font(.system(size: 12))
                            .foregroundColor(isCopied ? .green : .secondary)
                        
                        Text(isCopied ? "Copied!" : item.formattedTimestamp)
                            .font(.system(size: 11))
                            .foregroundColor(isCopied ? .green : .secondary)
                        
                        Spacer()
                    }
                }
            }
            .buttonStyle(ClipboardCardStyle(isCopied: isCopied))
            
            if !isCopied {
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                        .background(
                            Circle()
                                .fill(Color(.systemBackground))
                                .frame(width: 16, height: 16)
                        )
                }
                .buttonStyle(PlainButtonStyle())
                .padding(8)
            }
        }
    }
}
