import SwiftUI

@MainActor
class ChatMessageHandler {
    static func processMessage(content: String,
                               thread: Thread,
                               appState: AppState,
                               llm: LocalLLMProvider,
                               appManager: AppManager,
                               currentProvider: String) async -> String {
        if currentProvider == "local" {
            if let modelName = appManager.currentModelName {
                do {
                    return try await llm.generate(modelName: modelName,
                                                  thread: thread,
                                                  systemPrompt: appManager.systemPrompt,
                                                  images: appState.selectedImages)
                } catch {
                    return "Local model error: \(error.localizedDescription)"
                }
            }
            return "No local model selected. Please install a model in settings."
        } else {
            do {
                let response = try await appState.activeProvider.processText(
                    systemPrompt: appManager.systemPrompt,
                    userPrompt: content,
                    images: appState.selectedImages,
                    streaming: true
                )
                return response
            } catch {
                return "Error: \(error.localizedDescription)"
            }
        }
    }
}
