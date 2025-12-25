import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

@available(iOS 26.0, *)
@MainActor
class FoundationModelsProvider: ObservableObject, AIProvider {
    @Published var isProcessing = false
    #if canImport(FoundationModels)
    private var currentSession: LanguageModelSession?
    #endif
    private var currentTask: Task<Void, Never>?
    
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
        
        // Images are not supported by Foundation Models
        if !images.isEmpty {
            throw NSError(
                domain: "FoundationModelsAPI",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Foundation Models does not support image input."]
            )
        }
        
        isProcessing = true
        defer { isProcessing = false }
        
        // Create instructions from system prompt if provided
        let instructions: Instructions? = {
            if let systemPrompt = systemPrompt, !systemPrompt.isEmpty {
                return Instructions(systemPrompt)
            } else {
                return nil
            }
        }()
        
        // Create session with instructions
        let session = LanguageModelSession(
            model: model,
            instructions: instructions
        )
        currentSession = session
        
        do {
            if streaming {
                // For streaming, collect the stream into a single string
                let stream = session.streamResponse(to: userPrompt)
                
                // Collect final response (streaming is handled internally)
                let finalResponse = try await stream.collect()
                return finalResponse.content
            } else {
                // Non-streaming response
                let response = try await session.respond(to: userPrompt)
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
        #if canImport(FoundationModels)
        currentSession = nil
        #endif
    }
}

