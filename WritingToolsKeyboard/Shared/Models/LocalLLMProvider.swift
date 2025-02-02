import MLX
import MLXLLM
import MLXLMCommon
import MLXRandom
import SwiftUI

class LocalLLMProvider: ObservableObject, AIProvider {
    @Published var isProcessing = false
    @Published var running = false
    var cancelled = false

    @Published var output = ""
    @Published var modelInfo = ""
    @Published var progress = 0.0
    @Published var isDownloading = false
    @Published var downloadError: Error?

    enum LoadState {
        case idle
        case loaded(ModelContainer)
    }
    @Published var loadState: LoadState = .idle

    private let maxTokens = 4096
    private let generateParameters = GenerateParameters(temperature: 0.5)
    private static var randomSeeded = false

    init() {
        self.modelInfo = "Local LLM not loaded"
    }

    func cancel() {
        // Ensure UI updates on main actor.
        Task { @MainActor in
            self.isProcessing = false
            self.running = false
            self.cancelled = true
        }
    }

    func stop() {
        cancel()
    }

    // Process text using the loaded model container.
    func processText(systemPrompt: String? = "You are a helpful writing assistant.",
                     userPrompt: String,
                     images: [Data],
                     streaming: Bool = false) async throws -> String {
        // Ensure we have a loaded container.
        guard case .loaded(let container) = loadState else {
            throw AIError.modelNotLoaded
        }
        // Update UI state on main thread.
        await MainActor.run {
            self.running = true
            self.cancelled = false
            self.isProcessing = true
            self.output = ""
        }

        defer {
            Task { @MainActor in
                self.running = false
                self.isProcessing = false
            }
        }

        // Run OCR on attached images.
        var ocrExtractedText = ""
        for image in images {
            do {
                let recognized = try await OCRManager.shared.performOCR(on: image)
                if !recognized.isEmpty {
                    ocrExtractedText += recognized + "\n"
                }
            } catch {
                print("OCR error (LocalLLM): \(error.localizedDescription)")
            }
        }
        let combinedUserPrompt = ocrExtractedText.isEmpty ? userPrompt : "\(userPrompt)\n\nOCR Extracted Text:\n\(ocrExtractedText)"
        let finalPrompt = systemPrompt.map { "\($0)\n\n\(combinedUserPrompt)" } ?? combinedUserPrompt

        // Seed the random generator once.
        if !Self.randomSeeded {
            MLXRandom.seed(UInt64(Date().timeIntervalSinceReferenceDate * 1000))
            Self.randomSeeded = true
        }

        let result = try await container.perform { context in
            // Prepare the input (this runs off the main thread).
            let input = try await context.processor.prepare(input: .init(prompt: finalPrompt))
            // Generate text, updating output every few tokens.
            return try MLXLMCommon.generate(
                input: input,
                parameters: self.generateParameters,
                context: context
            ) { tokens in
                if tokens.count % 4 == 0 {
                    let text = context.tokenizer.decode(tokens: tokens)
                    Task { @MainActor in
                        self.output = text
                    }
                }
                if tokens.count >= self.maxTokens || self.cancelled {
                    return .stop
                } else {
                    return .more
                }
            }
        }

        if result.output != self.output {
            await MainActor.run {
                self.output = result.output
            }
        }
        return self.output
    }

    // Loads a model container for the given model name.
    func load(modelName: String) async throws -> ModelContainer {
        switch loadState {
        case .idle:
            guard let config = ModelConfiguration.availableModels.first(where: { $0.name == modelName }) else {
                throw AIError.modelNotLoaded
            }
            await MainActor.run {
                self.isDownloading = true
                self.downloadError = nil
                self.progress = 0.0
            }
            do {
                let container = try await LLMModelFactory.shared.loadContainer(configuration: config.model) { update in
                    Task { @MainActor in
                        self.progress = update.fractionCompleted
                        self.modelInfo = "Downloading \(config.name)"
                    }
                }
                await MainActor.run {
                    self.modelInfo = "Loaded \(config.name)"
                    self.loadState = .loaded(container)
                    self.isDownloading = false
                }
                return container
            } catch {
                await MainActor.run {
                    self.downloadError = error
                    self.loadState = .idle
                    self.isDownloading = false
                }
                throw error
            }
        case .loaded(let container):
            return container
        }
    }

    // Switches to a new model by loading it on a background thread.
    func switchModel(_ modelName: String) async {
        await MainActor.run {
            self.loadState = .idle
            self.progress = 0.0
        }
        do {
            let container = try await Task.detached(priority: .userInitiated) {
                return try await self.load(modelName: modelName)
            }.value
            await MainActor.run {
                self.loadState = .loaded(container)
            }
        } catch {
            print("Error loading model: \(error)")
        }
    }

    // Convenience wrapper that builds the prompt history from a chat thread and then generates text.
    func generate(modelName: String, thread: Thread, systemPrompt: String, images: [Data] = []) async throws -> String {
        // Load the model if needed.
        let container = try await load(modelName: modelName)
        let promptHistory = container.configuration.getPromptHistory(thread: thread, systemPrompt: systemPrompt)
        let textPrompt = promptHistory.map { "\($0["role"] ?? ""): \($0["content"] ?? "")" }
                                      .joined(separator: "\n\n")
        return try await processText(systemPrompt: nil, userPrompt: textPrompt, images: images, streaming: false)
    }
}
