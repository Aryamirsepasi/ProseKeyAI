import Foundation
import MLXLLM
import MLXLMCommon


extension ModelConfiguration {
    public static let llama_3_2_1b_4bit = ModelRegistry.llama3_2_1B_4bit

    public static let llama_3_2_3b_4bit = ModelRegistry.llama3_2_3B_4bit
    
    public static let phi_3_5_mini_4bit = ModelRegistry.phi3_5_4bit
    
    public static let gemma_2_2b_it_4bit = ModelRegistry.gemma_2_2b_it_4bit


    public static var availableModels: [(name: String, model: ModelConfiguration, size: Double)] = [
        (name: "llama_3_2_1b_4bit", model: llama_3_2_1b_4bit, size: 0.7),
        (name: "phi_3_5_mini_4bit", model: phi_3_5_mini_4bit, size: 1.2),
        (name: "llama_3_2_3b_4bit", model: llama_3_2_3b_4bit, size: 1.8),
        (name: "gemma_2_2b_it_4bit", model: gemma_2_2b_it_4bit, size: 2.15),
    ]
    
    public static var defaultModel = llama_3_2_3b_4bit

    func getPromptHistory(thread: Thread, systemPrompt: String) -> [[String: String]] {
        var history: [[String: String]] = []

        history.append([
            "role": "system",
            "content": systemPrompt,
        ])

        for message in thread.sortedMessages {
            history.append([
                "role": message.role.rawValue,
                "content": message.content
            ])
        }

        return history
    }
}
