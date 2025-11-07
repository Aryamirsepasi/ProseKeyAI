//
//  ClipboardHistoryManager.swift
//  ProseKey AI
//
//  Created on 2025-11-07.
//

import Foundation
import UIKit

@MainActor
class ClipboardHistoryManager: ObservableObject {
    static let shared = ClipboardHistoryManager()
    
    @Published private(set) var items: [ClipboardItem] = []
    
    private let defaults: UserDefaults?
    private let storageKey = "clipboard_history"
    private let maxItems = 50 // Maximum number of items to store
    
    private init() {
        self.defaults = UserDefaults(suiteName: "group.com.aryamirsepasi.writingtools")
        loadItems()
        // No clipboard monitoring; only add explicitly.
    }
    
    deinit {
        // No timer to clean up
    }
    
    // MARK: - Public Methods
    
    func addItem(content: String) {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        // Remove duplicate if exists (keep most recent)
        items.removeAll { $0.content == trimmed }
        
        // Add new item at the beginning
        let newItem = ClipboardItem(content: trimmed)
        items.insert(newItem, at: 0)
        
        // Limit the number of stored items
        if items.count > maxItems {
            items = Array(items.prefix(maxItems))
        }
        
        // Clean up expired items
        cleanExpiredItems()
        
        saveItems()
    }
    
    func copyItem(_ item: ClipboardItem) {
        UIPasteboard.general.string = item.content
        // Do not update lastClipboardContent—clipboard monitoring is not used
        // But update timestamp for the item
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            let updatedItem = ClipboardItem(id: item.id, content: item.content, timestamp: Date())
            items.remove(at: index)
            items.insert(updatedItem, at: 0)
            saveItems()
        }
        
        HapticsManager.shared.success()
    }
    
    func deleteItem(_ item: ClipboardItem) {
        items.removeAll { $0.id == item.id }
        saveItems()
        HapticsManager.shared.keyPress()
    }
    
    func clearAll() {
        items.removeAll()
        saveItems()
        HapticsManager.shared.success()
    }
    
    // MARK: - Private Methods
    
    private func cleanExpiredItems() {
        items.removeAll { $0.isExpired }
    }
    
    private func loadItems() {
        cleanExpiredItems() // Clean on load
        
        guard let data = defaults?.data(forKey: storageKey) else {
            items = []
            return
        }
        
        do {
            let decoder = JSONDecoder()
            var loadedItems = try decoder.decode([ClipboardItem].self, from: data)
            
            // Remove expired items
            loadedItems.removeAll { $0.isExpired }
            
            items = loadedItems
        } catch {
            print("Failed to load clipboard history: \(error)")
            items = []
        }
    }
    
    private func saveItems() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(items)
            defaults?.set(data, forKey: storageKey)
            defaults?.synchronize()
        } catch {
            print("Failed to save clipboard history: \(error)")
        }
    }
    
    var nonExpiredItems: [ClipboardItem] {
        items.filter { !$0.isExpired }
    }
}

