import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

class DownloadServiceWin {
    static let shared = DownloadServiceWin()
    
    var isDownloading = false
    var currentStatus = ""
    var downloadProgress: Double = 0.0
    
    private init() {}
    
    func download(url: String) {
        self.isDownloading = true
        self.downloadProgress = 0.0
        
        Task {
            var trackQueries: [String] = []
            
            await MainActor.run { self.currentStatus = "Analyzing link..." }
            
            if url.contains("youtube.com/playlist") || url.contains("&list=") {
                await MainActor.run { self.currentStatus = "Fetching YouTube playlist info..." }
                trackQueries = await fetchYouTubePlaylistTracks(from: url)
            } else if url.contains("spotify.com/track") {
                if let meta = await fetchSpotifyMetadata(from: url) {
                    trackQueries = ["ytsearch1:\(meta) audio"]
                } else {
                    trackQueries = [url]
                }
            } else if url.contains("spotify.com/playlist") || url.contains("spotify.com/album") {
                await MainActor.run { self.currentStatus = "Parsing Spotify playlist..." }
                trackQueries = await fetchSpotifyPlaylistTracks(from: url)
            } else {
                trackQueries = [url]
            }
            
            guard !trackQueries.isEmpty else {
                await MainActor.run {
                    self.currentStatus = "Error: No tracks found or link is private."
                    self.isDownloading = false
                }
                return
            }
            
            for (index, query) in trackQueries.enumerated() {
                let displayTitle = query.replacingOccurrences(of: "ytsearch1:", with: "").prefix(40)
                await MainActor.run {
                    self.currentStatus = "Downloading (\(index + 1)/\(trackQueries.count)): \(displayTitle)..."
                    self.downloadProgress = Double(index) / Double(trackQueries.count)
                }
                
                await runYtDlp(query: query)
            }
            
            await MainActor.run {
                self.currentStatus = "Success! All tracks imported."
                self.downloadProgress = 1.0
                self.isDownloading = false
                print("Windows: All downloads complete.")
            }
        }
    }
    
    private func fetchYouTubePlaylistTracks(from url: String) async -> [String] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "C:\\Windows\\System32\\cmd.exe")
        process.arguments = ["/c", "yt-dlp", "--get-title", "--flat-playlist", url]
        
        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        
        do {
            try process.run()
            let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            
            if let output = String(data: data, encoding: .utf8) {
                return output.components(separatedBy: .newlines).filter { !$0.isEmpty }
            }
        } catch {
            print("Windows YT Playlist Error: \(error.localizedDescription)")
        }
        return []
    }
    
    private func runYtDlp(query: String) async {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "C:\\Windows\\System32\\cmd.exe")
        
        // If it's a search query, use ytsearch1:
        let finalUrl = (query.contains("http") || query.contains("ytsearch1:")) ? query : "ytsearch1:\(query) audio"
        
        process.arguments = [
            "/c", "yt-dlp", "-x", "--audio-format", "mp3", "--audio-quality", "0",
            "--add-metadata", "--embed-thumbnail",
            finalUrl
        ]
        
        do {
            try process.run()
            process.waitUntilExit()
            print("Windows: Finished processing query: \(query)")
        } catch {
            print("Windows Download Error: \(error.localizedDescription)")
        }
    }
    
    private func fetchSpotifyPlaylistTracks(from url: String) async -> [String] {
        guard let url = URL(string: url) else { return [] }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let html = String(data: data, encoding: .utf8) else { return [] }
            
            let trackPattern = "\"name\":\"([^\"]+)\",\"type\":\"track\""
            let artistPattern = "\"name\":\"([^\"]+)\",\"type\":\"artist\""
            
            let trackRegex = try NSRegularExpression(pattern: trackPattern)
            let artistRegex = try NSRegularExpression(pattern: artistPattern)
            
            let trackMatches = trackRegex.matches(in: html, range: NSRange(html.startIndex..., in: html))
            let artistMatches = artistRegex.matches(in: html, range: NSRange(html.startIndex..., in: html))
            
            var tracks: [String] = []
            
            for i in 0..<trackMatches.count {
                if let trackRange = Range(trackMatches[i].range(at: 1), in: html) {
                    let trackName = String(html[trackRange])
                    var fullName = trackName
                    if i < artistMatches.count, let artistRange = Range(artistMatches[i].range(at: 1), in: html) {
                        let artistName = String(html[artistRange])
                        fullName = "\(trackName) - \(artistName)"
                    }
                    
                    if !tracks.contains(fullName) && trackName != "Spotify" {
                        tracks.append(fullName)
                    }
                }
            }
            return tracks
        } catch {
            return []
        }
    }
    
    private func fetchSpotifyMetadata(from url: String) async -> String? {
        guard let encodedUrl = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let oEmbedUrl = URL(string: "https://open.spotify.com/oembed?url=\(encodedUrl)") else {
            return nil
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: oEmbedUrl)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let title = json["title"] as? String {
                return title
            }
        } catch {
            print("Spotify Meta Error: \(error.localizedDescription)")
        }
        return nil
    }
}
