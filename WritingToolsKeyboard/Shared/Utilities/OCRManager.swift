import Foundation
import Vision
import UIKit 

class OCRManager {
    static let shared = OCRManager()
    private init() {}
    
    
    // Extracts text from a single image Data object.
    func extractText(from imageData: Data) async -> String {
        guard let uiImage = UIImage(data: imageData),
              let cgImage = uiImage.cgImage else {
            return ""
        }
        
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        return await withCheckedContinuation { continuation in
            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try requestHandler.perform([request])
                guard let observations = request.results else {
                    continuation.resume(returning: "")
                    return
                }
                let texts = observations.compactMap { $0.topCandidates(1).first?.string }
                continuation.resume(returning: texts.joined(separator: "\n"))
            } catch {
                continuation.resume(returning: "")
            }
        }
    }
    
    // Extracts text from an array of images.
    func extractText(from images: [Data]) async -> String {
        var combinedText = ""
        for imageData in images {
            let text = await extractText(from: imageData)
            if !text.isEmpty {
                combinedText += text + "\n"
            }
        }
        return combinedText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
