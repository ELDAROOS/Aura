import Foundation
// В реальном проекте на Windows здесь будет: import WinUI

class MainWindowWin {
    let audioPlayer = AudioPlayerServiceWin.shared
    let downloader = DownloadServiceWin.shared
    
    func render() {
        print("--- Aura Windows Interface ---")
        print("[ Search Music | Import Link ]")
        print("-------------------------------")
        print("Status: \(downloader.currentStatus)")
        print("Now Playing: \(audioPlayer.isPlaying ? "Playing" : "Paused")")
        print("Volume: \(Int(audioPlayer.volume * 100))%")
        print("-------------------------------")
        print("[ Previous ] [ Play/Pause ] [ Next ]")
    }
    
    // Эмуляция действий пользователя
    func onPlayClicked() {
        audioPlayer.togglePlayPause()
        render()
    }
    
    func onDownloadClicked(url: String) {
        downloader.download(url: url)
        render()
    }
}
