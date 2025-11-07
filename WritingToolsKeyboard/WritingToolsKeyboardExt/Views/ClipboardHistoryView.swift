//
//  ClipboardHistoryView.swift
//  ProseKey AI
//
//  Created on 2025-11-07.
//

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
        VStack(spacing: 0) {
            // Header
            headerView
            
            Divider()
            
            // Content
            if manager.nonExpiredItems.isEmpty {
                emptyStateView
            } else {
                clipboardGridView
            }
        }
    }
    
    private var headerView: some View {
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
            
            if !manager.nonExpiredItems.isEmpty {
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
                // Invisible button for layout balance
                Text("Clear")
                    .font(.system(size: 17))
                    .foregroundColor(.clear)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
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
        .frame(maxWidth: .infinity)
        .padding()
    }
    
    private var clipboardGridView: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(manager.nonExpiredItems) { item in
                    ClipboardItemCard(
                        item: item,
                        isCopied: copiedItemId == item.id,
                        onTap: {
                            handleItemTap(item)
                        },
                        onDelete: {
                            manager.deleteItem(item)
                        }
                    )
                }
            }
            .padding(12)
        }
    }
    
    private func handleItemTap(_ item: ClipboardItem) {
        // Copy to clipboard
        manager.copyItem(item)
        
        // Show copied animation
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            copiedItemId = item.id
        }
        
        // Insert into text field if we have a view controller
        viewController?.textDocumentProxy.insertText(item.content)
        
        // Reset animation and dismiss after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation {
                copiedItemId = nil
            }
            onDismiss()
        }
    }
}

struct ClipboardItemCard: View {
    let item: ClipboardItem
    let isCopied: Bool
    let onTap: () -> Void
    let onDelete: () -> Void
    
    @State private var isPressing = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: onTap) {
                VStack(alignment: .leading, spacing: 8) {
                    // Content
                    Text(item.displayText)
                        .font(.system(size: 14))
                        .foregroundColor(.primary)
                        .lineLimit(4)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Spacer()
                    
                    // Timestamp
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
                .scaleEffect(isPressing ? 0.95 : 1.0)
            }
            .buttonStyle(PlainButtonStyle())
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        withAnimation(.easeInOut(duration: 0.1)) {
                            isPressing = true
                        }
                    }
                    .onEnded { _ in
                        withAnimation(.easeInOut(duration: 0.1)) {
                            isPressing = false
                        }
                    }
            )
            
            // Delete button
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

