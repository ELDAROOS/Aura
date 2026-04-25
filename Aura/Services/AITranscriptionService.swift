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
        // Create recognizer for the file's locale or default
        let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US")) // Default to English, but it often auto-detects or can be improved
        
        guard let recognizer = recognizer, recognizer.isAvailable else {
            continuation.resume(throwing: NSError(domain: "AuraSpeech", code: 3, userInfo: [NSLocalizedDescriptionKey: "Speech recognizer is not available on this device."]))
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
