import MLX
import MLXLLM
import MLXLMCommon
import MLXRandom
import SwiftUI

@MainActor
class LocalLLMProvider: ObservableObject, AIProvider {
    @Published var isProcessing = false
    @Published var running = false
    var cancelled = false
    
    @Published var output = ""
    @Published var modelInfo = ""
    @Published var progress = 0.0
    @Published var isDownloading = false
    @Published var downloadError: Error?
    
    // Load state: either idle or loaded
    enum LoadState {
        case idle
        case loaded(ModelContainer)
    }
    @Published var loadState: LoadState = .idle
    
    private let maxTokens = 4096
    
    private let generateParameters = GenerateParameters(temperature: 0.5)
    
    init() {
        self.modelInfo = "Local LLM not loaded"
    }
    
    func cancel() {
        isProcessing = false
        cancelled = true
    }
    
    func stop() {
        cancel()
    }
    
    func processText(systemPrompt: String?, userPrompt: String) async throws -> String {
        guard case .loaded(let container) = loadState else {
            throw AIError.modelNotLoaded
        }
        running = true
        cancelled = false
        isProcessing = true
        output = ""
        
        defer {
            Task { @MainActor in
                self.running = false
                self.isProcessing = false
            }
        }
        
        // Combine system prompt + user prompt
        let finalPrompt = systemPrompt.map { "\($0)\n\n\(userPrompt)" } ?? userPrompt
        
        // Random seed
        MLXRandom.seed(UInt64(Date().timeIntervalSinceReferenceDate * 1000))
        
        let result = try await container.perform { context in
            let input = try await context.processor.prepare(
                input: .init(prompt: finalPrompt)
            )
            
            return try MLXLMCommon.generate(
                input: input,
                parameters: self.generateParameters,
                context: context
            ) { tokens in
                var cancelled = false
                Task { @MainActor in
                    cancelled = self.cancelled
                }
                
                if tokens.count >= self.maxTokens || cancelled {
                    return .stop
                } else {
                    return .more
                }
            }
        }
        
        if result.output != output {
            output = result.output
        }
        return output
    }
    
    // Helper to load a model from ModelConfiguration
    func load(modelName: String) async throws -> ModelContainer {
        switch loadState {
        case .idle:
            guard let config = ModelConfiguration.availableModels.first(where: { $0.name == modelName }) else {
                throw AIError.modelNotLoaded
            }
            
            // Start download
            isDownloading = true
            downloadError = nil
            progress = 0.0
            
            do {
                let container = try await LLMModelFactory.shared.loadContainer(configuration: config.model) { update in
                    Task { @MainActor in
                        self.progress = update.fractionCompleted
                        self.modelInfo = "Downloading \(config.name)"
                    }
                }
                
                modelInfo = "Loaded \(config.name)"
                loadState = .loaded(container)
                isDownloading = false
                return container
                
            } catch {
                downloadError = error
                loadState = .idle
                isDownloading = false
                throw error
            }
            
        case .loaded(let container):
            return container
        }
    }
    
    // Switch to a new model; will re-initiate load if needed
    func switchModel(_ modelName: String) async {
           // Reset to idle
           loadState = .idle
           progress = 0.0
           
           do {
               _ = try await load(modelName: modelName)
           } catch {
               print("Error loading model: \(error)")
           }
    }
}
