import SwiftUI

struct ClipboardHistoryView: View {
    @ObservedObject var manager: ClipboardHistoryManager
    weak var viewController: KeyboardViewController?
    let onDismiss: () -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    @State private var copiedItemId: UUID?
    @State private var showFullAccessAlert = false
    
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
        .alert("Full Access Required", isPresented: $showFullAccessAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Enable Full Access in Settings to use clipboard history.")
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
                        .font(.body.weight(.semibold))
                    Text("Back")
                        .font(.body)
                }
                .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            Text("Clipboard History")
                .font(.headline)
            
            Spacer()
            
            if hasItems {
                Button(action: {
                    HapticsManager.shared.keyPress()
                    manager.clearAll()
                }) {
                    Text("Clear")
                        .font(.body)
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            } else {
                Text("Clear")
                    .font(.body)
                    .foregroundStyle(.clear)
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
                .font(.largeTitle)
                .foregroundStyle(.secondary)

            Text("No Clipboard History")
                .font(.headline)
                .foregroundStyle(.primary)

            Text("Copy text to see it appear here")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private func clipboardGridView(items: [ClipboardItem]) -> some View {
        ScrollView(.vertical) {
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
        .scrollIndicators(.visible)
        .frame(maxHeight: .infinity)
    }
    
    private func handleItemTap(_ item: ClipboardItem) {
        guard viewController?.hasFullAccess == true else {
            HapticsManager.shared.error()
            showFullAccessAlert = true
            return
        }
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
                        .font(.footnote)
                        .foregroundStyle(.primary)
                        .lineLimit(4)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Spacer()
                    
                    HStack {
                        Image(systemName: isCopied ? "checkmark.circle.fill" : "doc.on.doc")
                            .font(.caption)
                            .foregroundStyle(isCopied ? .green : .secondary)
                        
                        Text(isCopied ? "Copied!" : item.formattedTimestamp)
                            .font(.caption2)
                            .foregroundStyle(isCopied ? .green : .secondary)
                        
                        Spacer()
                    }
                }
            }
            .buttonStyle(ClipboardCardStyle(isCopied: isCopied))
            
            if !isCopied {
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .background(
                            Circle()
                                .fill(Color(.systemBackground))
                                .frame(width: 16, height: 16)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Delete clipboard item")
                .padding(8)
            }
        }
    }
}
