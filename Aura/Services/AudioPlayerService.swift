import Foundation
import AVFoundation
import SwiftUI
import SwiftData

@Observable
class AudioPlayerService: NSObject {
    static let shared = AudioPlayerService()
    
    // Engine & Nodes
    private var engine = AVAudioEngine()
    private var playerNode = AVAudioPlayerNode()
    private var eqNode = AVAudioUnitEQ(numberOfBands: 10)
    
    // State
    var currentTrack: Track?
    var isPlaying = false
    var volume: Float = 0.8 {
        didSet { playerNode.volume = volume }
    }
    var currentTime: TimeInterval = 0
    var duration: TimeInterval = 0
    var isNowPlayingVisible = false
    var isShuffle = false
    var queue: [Track] = []
    
    // EQ Settings
    var eqBands: [Float] = Array(repeating: 0.0, count: 10) {
        didSet { updateEQ() }
    }
    var currentPreset: String = "Flat"
    
    private var timer: Timer?
    
    private override init() {
        super.init()
        setupEngine()
    }
    
    private func setupEngine() {
        engine.attach(playerNode)
        engine.attach(eqNode)
        
        let frequencies: [Float] = [32, 64, 125, 250, 500, 1000, 2000, 4000, 8000, 16000]
        for i in 0..<10 {
            let band = eqNode.bands[i]
            band.filterType = .parametric
            band.frequency = frequencies[i]
            band.bandwidth = 1.0
            band.bypass = false
        }
        
        let format = engine.mainMixerNode.outputFormat(forBus: 0)
        engine.connect(playerNode, to: eqNode, format: format)
        engine.connect(eqNode, to: engine.mainMixerNode, format: format)
        
        try? engine.start()
    }
    
    private func updateEQ() {
        for i in 0..<10 {
            eqNode.bands[i].gain = eqBands[i]
        }
    }
    
    func applyPreset(_ preset: String) {
        currentPreset = preset
        switch preset {
        case "Rock":
            eqBands = [4, 3, 2, 0, -1, -1, 1, 2, 3, 4]
        case "Jazz":
            eqBands = [3, 2, 1, 2, -1, -1, 0, 1, 2, 3]
        case "Bass Boost":
            eqBands = [6, 5, 4, 2, 0, 0, 0, 0, 0, 0]
        case "Flat":
            eqBands = Array(repeating: 0.0, count: 10)
        default:
            break
        }
    }
    
    func play(track: Track, in queue: [Track] = []) {
        guard let fileName = track.localFileName else { return }
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let url = documentsDirectory.appendingPathComponent(fileName)
        
        stop()
        
        do {
            let file = try AVAudioFile(forReading: url)
            let format = file.processingFormat
            duration = Double(file.length) / format.sampleRate
            
            playerNode.scheduleFile(file, at: nil, completionHandler: nil)
            
            if !engine.isRunning { try engine.start() }
            playerNode.play()
            
            currentTrack = track
            isPlaying = true
            startTimer()
        } catch {
            print("Playback Error: \(error.localizedDescription)")
        }
    }
    
    func togglePlayPause() {
        if isPlaying {
            playerNode.pause()
        } else {
            playerNode.play()
        }
        isPlaying.toggle()
    }
    
    func stop() {
        playerNode.stop()
        isPlaying = false
        timer?.invalidate()
        currentTime = 0
    }
    
    func nextTrack() {
        // Placeholder for future queue logic
    }
    
    func previousTrack() {
        // Placeholder for future queue logic
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, self.isPlaying else { return }
            
            if let lastRenderTime = self.playerNode.lastRenderTime,
               let playerTime = self.playerNode.playerTime(forNodeTime: lastRenderTime) {
                let sampleTime = Double(playerTime.sampleTime)
                let sampleRate = playerTime.sampleRate
                if sampleRate > 0 {
                    self.currentTime = sampleTime / sampleRate
                }
            }
        }
    }
    
    func seek(to time: TimeInterval) {
        self.currentTime = time
    }
    
    var timeString: String { formatTime(currentTime) }
    var totalTimeString: String { formatTime(duration) }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
