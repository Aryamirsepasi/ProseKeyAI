import Foundation
import SwiftUI

// A user-defined custom command with a name, prompt, and icon.
struct CustomCommand: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var prompt: String
    var icon: String
    
    init(id: UUID = UUID(), name: String, prompt: String, icon: String) {
        self.id = id
        self.name = name
        self.prompt = prompt
        self.icon = icon
    }
}

// Manages loading/saving custom commands from App Group user defaults
class CustomCommandsManager: ObservableObject {
    @Published private(set) var commands: [CustomCommand] = []
    
    private let suiteName = "group.com.aryamirsepasi.writingtools"
    private let storageKey = "custom_commands_list"
    
    init() {
        loadCommands()
    }
    
    func loadCommands() {
        guard let userDefaults = UserDefaults(suiteName: suiteName),
              let data = userDefaults.data(forKey: storageKey) else {
            return
        }
        do {
            let decoded = try JSONDecoder().decode([CustomCommand].self, from: data)
            commands = decoded
        } catch {
            print("Failed to decode custom commands: \(error)")
        }
    }
    
    private func saveCommands() {
        guard let userDefaults = UserDefaults(suiteName: suiteName) else { return }
        do {
            let data = try JSONEncoder().encode(commands)
            userDefaults.set(data, forKey: storageKey)
        } catch {
            print("Failed to encode/save custom commands: \(error)")
        }
    }
    
    func addCommand(_ command: CustomCommand) {
        commands.append(command)
        saveCommands()
    }
    
    func updateCommand(_ command: CustomCommand) {
        guard let idx = commands.firstIndex(where: { $0.id == command.id }) else { return }
        commands[idx] = command
        saveCommands()
    }
    
    func deleteCommand(_ command: CustomCommand) {
        commands.removeAll { $0.id == command.id }
        saveCommands()
    }
}
