import UIKit
import Vision

class OCRManager {
    static let shared = OCRManager()
    
    // Given image data (from pasteboard or file upload), run OCR and return any recognized text.
    func performOCR(on imageData: Data) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    // Create a UIImage from the data
                    guard let uiImage = UIImage(data: imageData) else {
                        throw NSError(domain: "OCRManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid image data"])
                    }
                    
                    // Attempt to get the CGImage. If it's not available, try creating one from a CIImage.
                    let cgImage: CGImage
                    if let existingCGImage = uiImage.cgImage {
                        cgImage = existingCGImage
                    } else if let ciImage = uiImage.ciImage,
                              let createdCGImage = CIContext().createCGImage(ciImage, from: ciImage.extent) {
                        cgImage = createdCGImage
                    } else {
                        throw NSError(domain: "OCRManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Cannot convert UIImage to CGImage"])
                    }
                    
                    // Create the OCR request
                    let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                    let request = VNRecognizeTextRequest { request, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else {
                            let observations = request.results as? [VNRecognizedTextObservation] ?? []
                            let recognizedText = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
                            continuation.resume(returning: recognizedText)
                        }
                    }
                    request.recognitionLevel = .accurate
                    request.usesLanguageCorrection = true
                    
                    // Perform the OCR request
                    try requestHandler.perform([request])
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
