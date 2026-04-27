import Foundation

class DownloadServiceWin {
    static let shared = DownloadServiceWin()
    
    var isDownloading = false
    var currentStatus = ""
    
    func download(url: String) {
        self.isDownloading = true
        self.currentStatus = "Downloading on Windows..."
        
        // В Windows мы ищем yt-dlp.exe в системных путях или рядом с приложением
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "C:\\Windows\\System32\\cmd.exe")
        process.arguments = ["/c", "yt-dlp", url, "-x", "--audio-format", "mp3"]
        
        do {
            try process.run()
            print("Windows: Download started for \(url)")
        } catch {
            print("Windows Error: \(error.localizedDescription)")
            self.isDownloading = false
        }
    }
}
