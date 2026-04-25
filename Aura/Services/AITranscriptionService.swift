import Foundation
import Speech
import AVFoundation

class AITranscriptionService {
    static func transcribe(url: URL, localeIdentifier: String? = nil) async throws -> String {
        // 1. Request Authorization
        return try await withCheckedThrowingContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                switch status {
                case .authorized:
                    // Proceed with transcription
                    startTranscription(url: url, localeIdentifier: localeIdentifier, continuation: continuation)
                case .denied, .restricted, .notDetermined:
                    continuation.resume(throwing: NSError(domain: "AuraSpeech", code: 1, userInfo: [NSLocalizedDescriptionKey: "Speech recognition not authorized. Please check System Settings."]))
                @unknown default:
                    continuation.resume(throwing: NSError(domain: "AuraSpeech", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unknown speech recognition error."]))
                }
            }
        }
    }
    
    private static func startTranscription(url: URL, localeIdentifier: String?, continuation: CheckedContinuation<String, Error>) {
        // Use provided locale or fallback to system locale
        let locale = localeIdentifier != nil ? Locale(identifier: localeIdentifier!) : Locale.current
        let recognizer = SFSpeechRecognizer(locale: locale)
        
        guard let recognizer = recognizer, recognizer.isAvailable else {
            let langName = locale.localizedString(forIdentifier: locale.identifier) ?? locale.identifier
            continuation.resume(throwing: NSError(domain: "AuraSpeech", code: 3, userInfo: [NSLocalizedDescriptionKey: "Speech recognizer is not available for \(langName) on this device."]))
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
