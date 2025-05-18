/*import Foundation
import Speech
import AVFoundation

@MainActor
class SpeechRecognizerViewModel: ObservableObject {
    @Published var transcribedText: String = ""
    @Published var isRecording: Bool = false
    @Published var debugStatus: String = ""

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    func requestPermission() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                self.debugStatus = "Speech auth: \(status.rawValue)"
                print("SpeechRecognizerViewModel: Speech auth status: \(status.rawValue)")
            }
        }
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                self.debugStatus += "\nMic permission: \(granted)"
                print("SpeechRecognizerViewModel: Mic permission: \(granted)")
            }
        }
    }

    func startRecording() {
        print("SpeechRecognizerViewModel: startRecording called")
        guard !audioEngine.isRunning else {
            print("SpeechRecognizerViewModel: audioEngine already running")
            return
        }
        transcribedText = ""
        isRecording = true
        debugStatus = "Starting recording..."

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            print("SpeechRecognizerViewModel: Audio session configured")
        } catch {
            debugStatus = "Audio session error: \(error.localizedDescription)"
            print("SpeechRecognizerViewModel: Audio session error: \(error)")
            return
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            debugStatus = "Failed to create recognition request"
            print("SpeechRecognizerViewModel: Failed to create recognition request")
            return
        }

        let inputNode = audioEngine.inputNode
        recognitionRequest.shouldReportPartialResults = true

        recognitionTask = recognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            if let result = result {
                self.transcribedText = result.bestTranscription.formattedString
                self.debugStatus = "Recognized: \(self.transcribedText)"
                print("SpeechRecognizerViewModel: Recognized: \(self.transcribedText)")
            }
            if let error = error {
                self.debugStatus = "Recognition error: \(error.localizedDescription)"
                print("SpeechRecognizerViewModel: Recognition error: \(error)")
            }
        }

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0) // Remove any previous tap
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
            // You can print here to confirm audio is being received
            // print("SpeechRecognizerViewModel: Audio buffer appended")
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
            debugStatus = "Audio engine started"
            print("SpeechRecognizerViewModel: Audio engine started")
        } catch {
            debugStatus = "Audio engine error: \(error.localizedDescription)"
            print("SpeechRecognizerViewModel: Audio engine error: \(error)")
        }
    }

    func stopRecording() {
        print("SpeechRecognizerViewModel: stopRecording called")
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
            print("SpeechRecognizerViewModel: Audio engine stopped")
        }
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        isRecording = false
        debugStatus = "Stopped recording"
    }
}
*/
