import Foundation
import SwiftUI

// A command for the keyboard - can be either built-in or custom
struct KeyboardCommand: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var prompt: String
    var icon: String
    var isBuiltIn: Bool
    
    init(id: UUID = UUID(), name: String, prompt: String, icon: String, isBuiltIn: Bool = false) {
        self.id = id
        self.name = name
        self.prompt = prompt
        self.icon = icon
        self.isBuiltIn = isBuiltIn
    }
    
    // Static factory to create a built-in command
    static func createBuiltIn(name: String, prompt: String, icon: String) -> KeyboardCommand {
        return KeyboardCommand(id: UUID(), name: name, prompt: prompt, icon: icon, isBuiltIn: true)
    }
}

// Manages loading/saving commands from App Group user defaults
class KeyboardCommandsManager: ObservableObject {
  @Published private(set) var commands: [KeyboardCommand] = [] {
    didSet {
      _builtInCommands = nil
      _customCommands = nil
    }
  }
    
    private var _builtInCommands: [KeyboardCommand]?
    private var _customCommands: [KeyboardCommand]?
    
    var builtInCommands: [KeyboardCommand] {
        if _builtInCommands == nil {
            _builtInCommands = commands.filter { $0.isBuiltIn }
        }
        return _builtInCommands!
    }
    
    var customCommands: [KeyboardCommand] {
        if _customCommands == nil {
            _customCommands = commands.filter { !$0.isBuiltIn }
        }
        return _customCommands!
    }
    
    private let suiteName = "group.com.aryamirsepasi.writingtools"
    private let storageKey = "keyboard_commands_list"
    private let builtInCommandsKey = "built_in_commands_shown"
    
    init() {
        loadCommands()
        ensureBuiltInsExist()
    }
    
    func loadCommands() {
        guard let userDefaults = UserDefaults(suiteName: suiteName),
              let data = userDefaults.data(forKey: storageKey) else {
            return
        }
        do {
            let decoded = try JSONDecoder().decode([KeyboardCommand].self, from: data)
            commands = decoded
        } catch {
            print("Failed to decode keyboard commands: \(error)")
            
            // Try loading legacy commands if available
            migrateFromLegacyCommands(userDefaults: userDefaults)
        }
    }
    
    private func migrateFromLegacyCommands(userDefaults: UserDefaults) {
        if let legacyData = userDefaults.data(forKey: "custom_commands_list") {
            do {
                struct LegacyCommand: Codable {
                    let id: UUID
                    var name: String
                    var prompt: String
                    var icon: String
                }
                
                let legacyCommands = try JSONDecoder().decode([LegacyCommand].self, from: legacyData)
                
                let migratedCommands = legacyCommands.map { legacy in
                    KeyboardCommand(id: legacy.id, name: legacy.name, prompt: legacy.prompt, icon: legacy.icon, isBuiltIn: false)
                }
                
                commands = migratedCommands
                saveCommands()
                
                // Optionally, clean up legacy data
                userDefaults.removeObject(forKey: "custom_commands_list")
            } catch {
                print("Failed to migrate legacy commands: \(error)")
            }
        }
    }
    
    private func saveCommands() {
        guard let userDefaults = UserDefaults(suiteName: suiteName) else { return }
        do {
            let data = try JSONEncoder().encode(commands)
            userDefaults.set(data, forKey: storageKey)
        } catch {
            print("Failed to encode/save keyboard commands: \(error)")
        }
    }
    
    func addCommand(_ command: KeyboardCommand) {
        commands.append(command)
        _builtInCommands = nil
        _customCommands = nil
        saveCommands()
    }
    
    func updateCommand(_ command: KeyboardCommand) {
        guard let idx = commands.firstIndex(where: { $0.id == command.id }) else { return }
        commands[idx] = command
        _builtInCommands = nil
        _customCommands = nil
        saveCommands()
    }
    
    func deleteCommand(_ command: KeyboardCommand) {
        // Don't allow deleting built-in commands
        if command.isBuiltIn {
            return
        }
        
        commands.removeAll { $0.id == command.id }
        _builtInCommands = nil
        _customCommands = nil
        saveCommands()
    }
    
    // Creates the built-in commands if they don't exist
    private func ensureBuiltInsExist() {
        let userDefaults = UserDefaults(suiteName: suiteName)
        let builtInsCreated = userDefaults?.bool(forKey: builtInCommandsKey) ?? false
        
        if commands.isEmpty || !builtInsCreated {
            createDefaultBuiltInCommands()
            userDefaults?.set(true, forKey: builtInCommandsKey)
        }
    }
    
    private func createDefaultBuiltInCommands() {
        let builtInCommands = [
            KeyboardCommand.createBuiltIn(
                name: "Proofread",
                prompt: """
                {
                  "role": "proofreading assistant",
                  "task": "correct grammar, spelling, and punctuation errors",
                  "rules": {
                    "acknowledge_content": false,
                    "add_explanations": false,
                    "engage_with_requests": false,
                    "output": "only corrected text",
                    "preserve": {
                      "tone": true,
                      "style": true,
                      "format": true,
                      "language": "input"
                    },
                    "input_is_content": true,
                    "preserve_formatting": true
                  },
                  "error_handling": {
                    "incompatible_text": "ERROR_TEXT_INCOMPATIBLE_WITH_REQUEST"
                  }
                }
                """,
                icon: "magnifyingglass"
            ),
            KeyboardCommand.createBuiltIn(
                name: "Rewrite",
                prompt: """
                {
                  "role": "rewriting assistant",
                  "task": "rephrase text while maintaining meaning",
                  "rules": {
                    "acknowledge_content": false,
                    "add_explanations": false,
                    "engage_with_requests": false,
                    "output": "only rewritten text",
                    "preserve": {
                      "language": "input",
                      "core_meaning": true,
                      "tone": true
                    },
                    "input_is_content": true
                  },
                  "error_handling": {
                    "incompatible_text": "ERROR_TEXT_INCOMPATIBLE_WITH_REQUEST"
                  }
                }
                """,
                icon: "arrow.triangle.2.circlepath"
            ),
            KeyboardCommand.createBuiltIn(
                name: "Friendly",
                prompt: """
                {
                  "role": "tone adjustment assistant",
                  "task": "make text warmer and more approachable",
                  "rules": {
                    "acknowledge_content": false,
                    "add_explanations": false,
                    "engage_with_requests": false,
                    "output": "only friendly version",
                    "preserve": {
                      "language": "input",
                      "core_message": true
                    },
                    "input_is_content": true
                  },
                  "error_handling": {
                    "incompatible_text": "ERROR_TEXT_INCOMPATIBLE_WITH_REQUEST"
                  }
                }
                """,
                icon: "face.smiling"
            ),
            KeyboardCommand.createBuiltIn(
                name: "Professional",
                prompt: """
                {
                  "role": "professional tone assistant",
                  "task": "make text more formal and business-appropriate",
                  "rules": {
                    "acknowledge_content": false,
                    "add_explanations": false,
                    "engage_with_requests": false,
                    "output": "only professional version",
                    "preserve": {
                      "language": "input",
                      "core_message": true
                    },
                    "input_is_content": true
                  },
                  "error_handling": {
                    "incompatible_text": "ERROR_TEXT_INCOMPATIBLE_WITH_REQUEST"
                  }
                }
                """,
                icon: "briefcase"
            ),
            KeyboardCommand.createBuiltIn(
                name: "Concise",
                prompt: """
                {
                  "role": "text condensing assistant",
                  "task": "make text more concise while preserving essential information",
                  "rules": {
                    "acknowledge_content": false,
                    "add_explanations": false,
                    "engage_with_requests": false,
                    "output": "only condensed version",
                    "preserve": {
                      "language": "input",
                      "essential_information": true
                    },
                    "input_is_content": true
                  },
                  "error_handling": {
                    "incompatible_text": "ERROR_TEXT_INCOMPATIBLE_WITH_REQUEST"
                  }
                }
                """,
                icon: "scissors"
            ),
            KeyboardCommand.createBuiltIn(
                name: "Summary",
                prompt: """
                {
                  "role": "summarization assistant",
                  "task": "create a clear, structured summary of key points",
                  "rules": {
                    "acknowledge_content_beyond_summary": false,
                    "add_explanations_outside_summary": false,
                    "engage_with_requests": false,
                    "output": "only summary with basic Markdown formatting",
                    "preserve": {
                      "language": "input"
                    },
                    "input_is_content": true
                  },
                  "error_handling": {
                    "incompatible_text": "ERROR_TEXT_INCOMPATIBLE_WITH_REQUEST"
                  }
                }
                """,
                icon: "doc.text"
            ),
            KeyboardCommand.createBuiltIn(
                name: "Key Points",
                prompt: """
                {
                  "role": "key points extraction assistant",
                  "task": "extract and list main points clearly",
                  "rules": {
                    "acknowledge_content_beyond_key_points": false,
                    "add_explanations_outside_key_points": false,
                    "engage_with_requests": false,
                    "output": "only key points in Markdown list format",
                    "preserve": {
                      "language": "input"
                    },
                    "input_is_content": true
                  },
                  "error_handling": {
                    "incompatible_text": "ERROR_TEXT_INCOMPATIBLE_WITH_REQUEST"
                  }
                }
                """,
                icon: "list.bullet"
            ),
            KeyboardCommand.createBuiltIn(
                name: "Table",
                prompt: """
                {
                  "role": "table conversion assistant",
                  "task": "organize information in a clear Markdown table",
                  "rules": {
                    "acknowledge_content_beyond_table": false,
                    "add_explanations_outside_table": false,
                    "engage_with_requests": false,
                    "output": "only Markdown table",
                    "preserve": {
                      "language": "input"
                    },
                    "input_is_content": true
                  },
                  "error_handling": {
                    "incompatible_text": "ERROR_TEXT_INCOMPATIBLE_WITH_REQUEST"
                  }
                }
                """,
                icon: "tablecells"
            )
        ]
        
        // Add built-in commands, but don't replace existing ones with the same name
        let existingCommandNames = Set(commands.map { $0.name })
        
        for command in builtInCommands {
            if !existingCommandNames.contains(command.name) {
                commands.append(command)
            }
        }
        
        saveCommands()
    }
}
