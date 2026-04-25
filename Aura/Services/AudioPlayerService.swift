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
    
    private var timer: Timer?
    
    private override init() {
        super.init()
    }
    
    func play(track: Track) {
        print("DEBUG: Attempting to play track: \(track.title)")
        guard let fileName = track.localFileName else {
            print("DEBUG: ERROR - No localFileName found for track: \(track.title). Try re-dragging the file.")
            return
        }
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        print("DEBUG: Full file URL: \(fileURL.path)")
        
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            print("DEBUG: ERROR - File does not exist at path: \(fileURL.path)")
            return
        }
        
        do {
            player = try AVAudioPlayer(contentsOf: fileURL)
            player?.delegate = self
            player?.prepareToPlay()
            let success = player?.play() ?? false
            if success {
                currentTrack = track
                isPlaying = true
                startTimer()
                print("DEBUG: Playback started successfully.")
                track.playCount += 1
            } else {
                print("DEBUG: ERROR - AVAudioPlayer.play() returned false.")
            }
        } catch {
            print("DEBUG: ERROR - AVAudioPlayer failed: \(error.localizedDescription)")
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
    
    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.player else { return }
            self.playbackProgress = player.currentTime / player.duration
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        stopTimer()
        playbackProgress = 0.0
    }
}
