import Foundation

class DownloadServiceWin {
    static let shared = DownloadServiceWin()
    
    var isDownloading = false
    var currentStatus = ""
    
    func download(url: String) {
        self.isDownloading = true
        
        // Spotify Bridge logic
        var finalUrl = url
        if url.contains("spotify.com") {
            self.currentStatus = "Windows: Converting Spotify link to YouTube search..."
            // В реальности здесь будет вызов парсера метаданных Spotify
            finalUrl = "ytsearch1:audio from spotify link" 
        }
        
        self.currentStatus = "Downloading: \(finalUrl)"
        
        let process = Process()
        // В Windows используем cmd для запуска yt-dlp
        process.executableURL = URL(fileURLWithPath: "C:\\Windows\\System32\\cmd.exe")
        process.arguments = ["/c", "yt-dlp", finalUrl, "-x", "--audio-format", "mp3", "--add-metadata"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            print("Windows: Started download process.")
            
            // На Windows нужно следить за завершением через дескрипторы
            process.terminationHandler = { _ in
                self.isDownloading = false
                print("Windows: Download complete.")
            }
        } catch {
            print("Windows Download Error: \(error.localizedDescription)")
            self.isDownloading = false
        }
    }
}
