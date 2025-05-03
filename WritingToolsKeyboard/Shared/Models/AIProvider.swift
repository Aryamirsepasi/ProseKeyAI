import Foundation

@MainActor
protocol AIProvider: ObservableObject {
    var isProcessing: Bool { get set }
    func processText(systemPrompt: String?, userPrompt: String, images: [Data], streaming: Bool) async throws -> String
    func cancel()
}
