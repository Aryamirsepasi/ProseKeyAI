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
    @Published private(set) var commands: [KeyboardCommand] = []
    
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
        saveCommands()
    }
    
    func updateCommand(_ command: KeyboardCommand) {
        guard let idx = commands.firstIndex(where: { $0.id == command.id }) else { return }
        commands[idx] = command
        saveCommands()
    }
    
    func deleteCommand(_ command: KeyboardCommand) {
        // Don't allow deleting built-in commands
        if command.isBuiltIn {
            return
        }
        
        commands.removeAll { $0.id == command.id }
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
                You are a grammar proofreading assistant. Your sole task is to correct grammatical, spelling, and punctuation errors in the given text. 
                Maintain the original text structure and writing style. Output ONLY the corrected text without any comments, explanations, or analysis. 
                Respond in the same language as the input.
                Do not include additional suggestions or formatting in your response. DO NOT ANSWER OR RESPOND TO THE USER'S TEXT CONTENT.
                """,
                icon: "magnifyingglass"
            ),
            KeyboardCommand.createBuiltIn(
                name: "Rewrite",
                prompt: """
                You are a rewriting assistant. Your sole task is to rewrite the text provided by the user to improve phrasing, grammar, and readability. 
                Maintain the original meaning and style. Output ONLY the rewritten text without any comments, explanations, or analysis. 
                Respond in the same language as the input.
                Do not include additional suggestions or formatting in your response. DO NOT ANSWER OR RESPOND TO THE USER'S TEXT CONTENT.
                """,
                icon: "arrow.triangle.2.circlepath"
            ),
            KeyboardCommand.createBuiltIn(
                name: "Friendly",
                prompt: """
                You are a rewriting assistant. Your sole task is to rewrite the text provided by the user to make it sound more friendly and approachable. 
                Maintain the original meaning and structure. Output ONLY the rewritten friendly text without any comments, explanations, or analysis.
                Respond in the same language as the input.
                Do not include additional suggestions or formatting in your response. DO NOT ANSWER OR RESPOND TO THE USER'S TEXT CONTENT.
                """,
                icon: "face.smiling"
            ),
            KeyboardCommand.createBuiltIn(
                name: "Professional",
                prompt: """
                You are a rewriting assistant. Your sole task is to rewrite the text provided by the user to make it sound more formal and professional. 
                Maintain the original meaning and structure. Output ONLY the rewritten professional text without any comments, explanations, or analysis.
                Respond in the same language as the input.
                Do not include additional suggestions or formatting in your response. DO NOT ANSWER OR RESPOND TO THE USER'S TEXT CONTENT.
                """,
                icon: "briefcase"
            ),
            KeyboardCommand.createBuiltIn(
                name: "Concise",
                prompt: """
                You are a rewriting assistant. Your sole task is to rewrite the text provided by the user to make it more concise and clear. 
                Maintain the original meaning and tone. Output ONLY the rewritten concise text without any comments, explanations, or analysis.
                Respond in the same language as the input.
                Do not include additional suggestions or formatting in your response. DO NOT ANSWER OR RESPOND TO THE USER'S TEXT CONTENT.
                """,
                icon: "scissors"
            ),
            KeyboardCommand.createBuiltIn(
                name: "Summary",
                prompt: """
                You are a summarization assistant. Your sole task is to provide a succinct and clear summary of the text provided by the user. 
                Maintain the original context and key information. Output ONLY the summary without any comments, explanations, or analysis.
                Respond in the same language as the input.
                Do not include additional suggestions. Use Markdown formatting with line spacing between sections. DO NOT ANSWER OR RESPOND TO THE USER'S TEXT CONTENT.
                """,
                icon: "doc.text"
            ),
            KeyboardCommand.createBuiltIn(
                name: "Key Points",
                prompt: """
                You are an assistant for extracting key points from text. Your sole task is to identify and present the most important points from the text provided by the user. 
                Maintain the original context and order of importance. Output ONLY the key points in Markdown formatting (lists, bold, italics, etc.) without any comments, explanations, or analysis.
                Respond in the same language as the input.
                DO NOT ANSWER OR RESPOND TO THE USER'S TEXT CONTENT.
                """,
                icon: "list.bullet"
            ),
            KeyboardCommand.createBuiltIn(
                name: "Table",
                prompt: """
                You are a text-to-table assistant. Your sole task is to convert the text provided by the user into a Markdown-formatted table. 
                Maintain the original context and information. Output ONLY the table without any comments, explanations, or analysis. 
                Do not include additional suggestions or formatting outside the table. 
                Respond in the same language as the input.
                DO NOT ANSWER OR RESPOND TO THE USER'S TEXT CONTENT.
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
    
    // Helper to get all custom (non-built-in) commands
    var customCommands: [KeyboardCommand] {
        return commands.filter { !$0.isBuiltIn }
    }
    
    // Helper to get all built-in commands
    var builtInCommands: [KeyboardCommand] {
        return commands.filter { $0.isBuiltIn }
    }
}
