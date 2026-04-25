import Foundation
import Speech
import AVFoundation

class AITranscriptionService {
    static func transcribe(url: URL) async throws -> String {
        // 1. Request Authorization
        return try await withCheckedThrowingContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                switch status {
                case .authorized:
                    // Proceed with transcription
                    startTranscription(url: url, continuation: continuation)
                case .denied, .restricted, .notDetermined:
                    continuation.resume(throwing: NSError(domain: "AuraSpeech", code: 1, userInfo: [NSLocalizedDescriptionKey: "Speech recognition not authorized. Please check System Settings."]))
                @unknown default:
                    continuation.resume(throwing: NSError(domain: "AuraSpeech", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unknown speech recognition error."]))
                }
            }
        }
    }
    
    private static func startTranscription(url: URL, continuation: CheckedContinuation<String, Error>) {
        // Use the system's current locale to support any language the user has configured
        let recognizer = SFSpeechRecognizer() // Automatically uses system locale
        
        guard let recognizer = recognizer, recognizer.isAvailable else {
            continuation.resume(throwing: NSError(domain: "AuraSpeech", code: 3, userInfo: [NSLocalizedDescriptionKey: "Speech recognizer is not available for your language or on this device."]))
            return
        }
        
        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = false
        
        // This is important for long audio files
        if #available(macOS 10.15, *) {
            request.requiresOnDeviceRecognition = false // Use Apple's servers for better accuracy if available
        }
        
        recognizer.recognitionTask(with: request) { result, error in
            if let error = error {
                continuation.resume(throwing: error)
            } else if let result = result {
                if result.isFinal {
                    continuation.resume(returning: result.bestTranscription.formattedString)
                }
            }
        }
    }
}
