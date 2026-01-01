import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

@available(iOS 26.0, *)
@MainActor
class FoundationModelsProvider: ObservableObject, AIProvider {
    @Published var isProcessing = false
    private var currentTask: Task<String, Error>?

    /// Returns the user's preferred language identifier for the Foundation Model
    /// Uses two-letter ISO 639 code format (e.g., "en", "de", "zh")
    private var preferredLanguageIdentifier: String {
        // Get the preferred language from system settings
        if let preferredLanguage = Locale.preferredLanguages.first {
            // Extract just the language code (e.g., "en" from "en-US")
            let languageCode = Locale(identifier: preferredLanguage).language.languageCode?.identifier ?? "en"
            return languageCode
        }
        return "en"
    }

    /// Returns a human-readable language name for instructions
    private var preferredLanguageName: String {
        if let preferredLanguage = Locale.preferredLanguages.first {
            let locale = Locale(identifier: preferredLanguage)
            // Get language name in English for the instructions
            if let languageCode = locale.language.languageCode {
                return Locale(identifier: "en").localizedString(forLanguageCode: languageCode.identifier) ?? "English"
            }
        }
        return "English"
    }

    var isAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            return SystemLanguageModel.default.isAvailable
        }
        #endif
        return false
    }

    #if canImport(FoundationModels)
    @available(iOS 26.0, *)
    var availability: SystemLanguageModel.Availability {
        return SystemLanguageModel.default.availability
    }
    #endif

    func processText(systemPrompt: String?, userPrompt: String, images: [Data], streaming: Bool) async throws -> String {
        #if canImport(FoundationModels)
        // Images are not supported by Foundation Models
        if !images.isEmpty {
            throw NSError(
                domain: "FoundationModelsAPI",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Foundation Models does not support image input."]
            )
        }

        currentTask?.cancel()
        isProcessing = true
        defer {
            isProcessing = false
            currentTask = nil
        }

        let languageName = preferredLanguageName
        let task = Task.detached(priority: .userInitiated) { () throws -> String in
            try Task.checkCancellation()

            // Check availability
            let model = SystemLanguageModel.default
            guard model.isAvailable else {
                let reason: String
                switch model.availability {
                case .available:
                    reason = "Unknown error"
                case .unavailable(let unavailableReason):
                    switch unavailableReason {
                    case .appleIntelligenceNotEnabled:
                        reason = "Apple Intelligence is not enabled. Please enable it in Settings."
                    case .deviceNotEligible:
                        reason = "This device does not support Apple Intelligence."
                    case .modelNotReady:
                        reason = "The model is not ready yet. It may still be downloading."
                    @unknown default:
                        reason = "The model is unavailable."
                    }
                }
                throw NSError(
                    domain: "FoundationModelsAPI",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: reason]
                )
            }

            // Build instructions with language preference
            // Apple recommends: "The user's preferred language is XX" in the instructions
            let languageInstruction = "The user's preferred language is \(languageName). Always respond in \(languageName)."

            let finalInstructions: Instructions
            if let systemPrompt = systemPrompt, !systemPrompt.isEmpty {
                // Combine language instruction with system prompt
                finalInstructions = Instructions("\(languageInstruction)\n\n\(systemPrompt)")
            } else {
                finalInstructions = Instructions(languageInstruction)
            }

            // Create session with instructions
            let session = LanguageModelSession(
                model: model,
                instructions: finalInstructions
            )

            do {
                if streaming {
                    // For streaming, collect the stream into a single string
                    let stream = session.streamResponse(to: userPrompt)

                    // Collect final response (streaming is handled internally)
                    let finalResponse = try await stream.collect()
                    try Task.checkCancellation()
                    return finalResponse.content
                } else {
                    // Non-streaming response
                    let response = try await session.respond(to: userPrompt)
                    try Task.checkCancellation()
                    return response.content
                }
            } catch let error as LanguageModelSession.GenerationError {
                let errorMessage: String
                switch error {
                case .guardrailViolation(let context):
                    errorMessage = "Content was blocked by safety guardrails: \(context.debugDescription)"
                case .exceededContextWindowSize(let context):
                    errorMessage = "Text is too long. Please shorten your input: \(context.debugDescription)"
                case .unsupportedLanguageOrLocale(let context):
                    errorMessage = "Language not supported: \(context.debugDescription)"
                case .refusal(let refusal, let context):
                    errorMessage = "Request was refused: \(context.debugDescription)"
                case .decodingFailure(let context):
                    errorMessage = "Failed to decode response: \(context.debugDescription)"
                case .assetsUnavailable(let context):
                    errorMessage = "Model assets unavailable: \(context.debugDescription)"
                case .rateLimited(let context):
                    errorMessage = "Rate limited: \(context.debugDescription)"
                case .concurrentRequests(let context):
                    errorMessage = "Concurrent request error: \(context.debugDescription)"
                case .unsupportedGuide(let context):
                    errorMessage = "Unsupported guide: \(context.debugDescription)"
                @unknown default:
                    errorMessage = "Generation error: \(error.localizedDescription)"
                }
                throw NSError(
                    domain: "FoundationModelsAPI",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: errorMessage]
                )
            } catch {
                throw NSError(
                    domain: "FoundationModelsAPI",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Foundation Models error: \(error.localizedDescription)"]
                )
            }
        }

        currentTask = task
        return try await task.value
        #else
        throw NSError(
            domain: "FoundationModelsAPI",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "Foundation Models framework is not available."]
        )
        #endif
    }
    
    func cancel() {
        currentTask?.cancel()
        currentTask = nil
        isProcessing = false
    }
}
