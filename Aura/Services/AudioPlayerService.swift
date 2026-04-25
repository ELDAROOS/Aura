import Foundation
import AVFoundation
import Observation

@Observable
class AudioPlayerService: NSObject, AVAudioPlayerDelegate {
    static let shared = AudioPlayerService()
    
    var player: AVAudioPlayer?
    var currentTrack: Track?
    var isPlaying = false
    var playbackProgress: Double = 0.0
    var volume: Float = 0.8 {
        didSet {
            player?.volume = volume
        }
    }
    
    // Queue and Shuffle properties
    var queue: [Track] = []
    var isShuffle = false
    var currentIndex: Int = 0
    
    var currentTime: TimeInterval = 0
    var duration: TimeInterval = 0
    
    var timeString: String {
        formatTime(currentTime)
    }
    
    var totalTimeString: String {
        formatTime(duration)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private var timer: Timer?
    
    private override init() {
        super.init()
    }
    
    func play(track: Track, in tracks: [Track] = []) {
        if !tracks.isEmpty {
            self.queue = tracks
            self.currentIndex = tracks.firstIndex(where: { $0.uuid == track.uuid }) ?? 0
        } else if !queue.contains(where: { $0.uuid == track.uuid }) {
            self.queue.append(track)
            self.currentIndex = queue.count - 1
        }
        
        loadAndPlay(track: track)
    }
    
    private func loadAndPlay(track: Track) {
        guard let fileName = track.localFileName else {
            print("DEBUG: ERROR - No localFileName found for track: \(track.title)")
            return
        }
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        do {
            player = try AVAudioPlayer(contentsOf: fileURL)
            player?.delegate = self
            player?.volume = volume
            player?.prepareToPlay()
            if player?.play() ?? false {
                currentTrack = track
                isPlaying = true
                duration = player?.duration ?? 0
                startTimer()
                track.playCount += 1
            }
        } catch {
            print("DEBUG: ERROR - AVAudioPlayer failed: \(error.localizedDescription)")
        }
    }
    
    func togglePlayPause() {
        guard let player = player else { return }
        if player.isPlaying {
            player.pause()
            isPlaying = false
            stopTimer()
        } else {
            player.play()
            isPlaying = true
            startTimer()
        }
    }
    
    func nextTrack() {
        guard !queue.isEmpty else { return }
        
        if isShuffle {
            currentIndex = Int.random(in: 0..<queue.count)
        } else {
            currentIndex = (currentIndex + 1) % queue.count
        }
        
        loadAndPlay(track: queue[currentIndex])
    }
    
    func previousTrack() {
        guard !queue.isEmpty else { return }
        currentIndex = (currentIndex - 1 + queue.count) % queue.count
        loadAndPlay(track: queue[currentIndex])
    }
    
    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.player else { return }
            self.currentTime = player.currentTime
            self.playbackProgress = player.currentTime / player.duration
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func seek(to time: TimeInterval) {
        player?.currentTime = time
        currentTime = time
        playbackProgress = time / (player?.duration ?? 1)
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        nextTrack() // Automatically play next track
    }
}
