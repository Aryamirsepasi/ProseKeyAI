import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif
#if canImport(NaturalLanguage)
import NaturalLanguage
#endif

@available(iOS 26.0, *)
@MainActor
class FoundationModelsProvider: ObservableObject, AIProvider {
    @Published var isProcessing = false
    private var currentTask: Task<String, Error>?

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

    private enum LanguageSource {
        case input
        case system
    }

    nonisolated private func makeLanguageInstruction(
        for userText: String,
        model: SystemLanguageModel
    ) -> String {
        if let preference = languagePreference(for: userText, model: model) {
            let languageTag = languageTag(for: preference.locale)
            switch preference.source {
            case .input:
                return "The user's input is in \(preference.name) (\(languageTag)). Respond in \(preference.name)."
            case .system:
                return "The user's preferred language is \(preference.name) (\(languageTag)). Respond in \(preference.name)."
            }
        }

        return "Respond in the same language as the user's input."
    }

    nonisolated private func languagePreference(
        for userText: String,
        model: SystemLanguageModel
    ) -> (name: String, locale: Locale, source: LanguageSource)? {
        if let detectedIdentifier = detectedLanguageIdentifier(for: userText),
           let detectedLocale = supportedLocale(for: detectedIdentifier, model: model) {
            return (languageName(for: detectedLocale), detectedLocale, .input)
        }

        if let systemIdentifier = Locale.preferredLanguages.first,
           let systemLocale = supportedLocale(for: systemIdentifier, model: model) {
            return (languageName(for: systemLocale), systemLocale, .system)
        }

        return nil
    }

    nonisolated private func supportedLocale(for identifier: String, model: SystemLanguageModel) -> Locale? {
        let locale = Locale(identifier: identifier)
        if model.supportsLocale(locale) {
            return locale
        }

        if let languageCode = locale.language.languageCode?.identifier {
            let languageLocale = Locale(identifier: languageCode)
            if model.supportsLocale(languageLocale) {
                return languageLocale
            }
        }

        return nil
    }

    nonisolated private func languageName(for locale: Locale) -> String {
        let languageCode = locale.language.languageCode?.identifier ?? locale.identifier
        return Locale(identifier: "en").localizedString(forLanguageCode: languageCode) ?? languageCode
    }

    nonisolated private func languageTag(for locale: Locale) -> String {
        locale.identifier.replacingOccurrences(of: "_", with: "-")
    }

    nonisolated private func detectedLanguageIdentifier(for text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        #if canImport(NaturalLanguage)
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(trimmed)
        guard let language = recognizer.dominantLanguage,
              language != .undetermined else {
            return nil
        }
        return language.rawValue
        #else
        return nil
        #endif
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
            let languageInstruction = self.makeLanguageInstruction(for: userPrompt, model: model)

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
