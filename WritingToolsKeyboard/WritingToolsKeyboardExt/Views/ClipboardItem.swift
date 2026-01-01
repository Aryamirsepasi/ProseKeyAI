//
//  ClipboardItem.swift
//  ProseKey AI
//
//  Created on 2025-11-07.
//

import Foundation

struct ClipboardItem: Identifiable, Codable {
    let id: UUID
    let content: String
    let timestamp: Date
    
    init(id: UUID = UUID(), content: String, timestamp: Date = Date()) {
        self.id = id
        self.content = content
        self.timestamp = timestamp
    }
    
    var isExpired: Bool {
        let expirationInterval: TimeInterval = 24 * 60 * 60 // 24 hours
        return Date().timeIntervalSince(timestamp) > expirationInterval
    }
    
    var displayText: String {
        // Trim and limit text for display
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count > 100 {
            return String(trimmed.prefix(100)) + "..."
        }
        return trimmed
    }
    
    var formattedTimestamp: String {
        Self.relativeFormatter.localizedString(for: timestamp, relativeTo: Date())
    }

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter
    }()
}
