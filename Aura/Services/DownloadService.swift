import Foundation
import SwiftData

@Observable
class DownloadService {
    static let shared = DownloadService()
    
    var isDownloading = false
    var downloadProgress: Double = 0.0
    var currentStatus: String = ""
    
    private init() {}
    
    func download(url: String, modelContext: ModelContext) {
        isDownloading = true
        currentStatus = "Analyzing link..."
        downloadProgress = 0.0
        
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        // Path detection
        let possibleYtDlpPaths = ["/opt/homebrew/bin/yt-dlp", "/usr/local/bin/yt-dlp", "/usr/bin/yt-dlp"]
        let ytDlpPath = possibleYtDlpPaths.first(where: { FileManager.default.fileExists(atPath: $0) })
        guard let finalYtDlpPath = ytDlpPath else {
            self.currentStatus = "Error: yt-dlp not found. Disable App Sandbox in Xcode."
            self.isDownloading = false
            return
        }
        
        Task {
            // 1. Identify what we are downloading
            var trackQueries: [String] = []
            
            if url.contains("youtube.com/playlist") || url.contains("&list=") {
                await MainActor.run { self.currentStatus = "Fetching YouTube playlist info..." }
                trackQueries = await fetchYouTubePlaylistTracks(executable: finalYtDlpPath, from: url)
            } else if url.contains("spotify.com/track") {
                if let meta = await fetchSpotifyMetadata(from: url) {
                    trackQueries = ["ytsearch1:\(meta) audio"]
                }
            } else if url.contains("spotify.com/playlist") || url.contains("spotify.com/album") {
                await MainActor.run { self.currentStatus = "Parsing Spotify... (Basic scraper)" }
                trackQueries = await fetchSpotifyPlaylistTracks(from: url)
            } else {
                trackQueries = [url] // Direct link or query
            }
            
            guard !trackQueries.isEmpty else {
                await MainActor.run {
                    self.currentStatus = "Error: No tracks found or link is private."
                    self.isDownloading = false
                }
                return
            }
            
            // 2. Process the queue
            for (index, query) in trackQueries.enumerated() {
                let displayTitle = query.replacingOccurrences(of: "ytsearch1:", with: "").prefix(40)
                await MainActor.run {
                    self.currentStatus = "Downloading (\(index + 1)/\(trackQueries.count)): \(displayTitle)..."
                    self.downloadProgress = Double(index) / Double(trackQueries.count)
                }
                
                let success = await runYtDlp(executable: finalYtDlpPath, url: query, outputDir: documentsDir)
                
                if success {
                    await scanForNewFiles(in: documentsDir, modelContext: modelContext)
                }
            }
            
            await MainActor.run {
                self.currentStatus = "Success! All tracks imported."
                self.downloadProgress = 1.0
                self.isDownloading = false
            }
        }
    }
    
    private func fetchYouTubePlaylistTracks(executable: String, from url: String) async -> [String] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = ["--get-title", "--flat-playlist", url]
        
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
            print("YT Playlist Error: \(error.localizedDescription)")
        }
        return []
    }
    
    private func runYtDlp(executable: String, url: String, outputDir: URL) async -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        
        var env = ProcessInfo.processInfo.environment
        env["PATH"] = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
        process.environment = env
        
        let possibleFfmpegPaths = ["/opt/homebrew/bin/ffmpeg", "/usr/local/bin/ffmpeg", "/usr/bin/ffmpeg"]
        let ffmpegPath = possibleFfmpegPaths.first(where: { FileManager.default.fileExists(atPath: $0) }) ?? "/usr/bin/ffmpeg"
        
        // If it's a search query, use ytsearch1:
        let finalUrl = (url.contains("http") || url.contains("ytsearch1:")) ? url : "ytsearch1:\(url) audio"
        
        process.arguments = [
            "-x", "--audio-format", "mp3", "--audio-quality", "0",
            "--add-metadata", "--embed-thumbnail",
            "--ffmpeg-location", ffmpegPath,
            "-o", "\(outputDir.path)/%(title)s.%(ext)s",
            finalUrl
        ]
        
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
    
    private func fetchSpotifyPlaylistTracks(from url: String) async -> [String] {
        guard let url = URL(string: url) else { return [] }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let html = String(data: data, encoding: .utf8) else { return [] }
            
            // Regex to find track names and artists in the Spotify meta tags
            // Usually found as: <meta property="music:song" content=".../track/ID">
            // But we want the titles. We can find them in the JSON state or by scraping.
            // A common pattern in Spotify HTML: "name":"Song Name","type":"track"
            let trackPattern = "\"name\":\"([^\"]+)\",\"type\":\"track\""
            let artistPattern = "\"name\":\"([^\"]+)\",\"type\":\"artist\""
            
            let trackRegex = try NSRegularExpression(pattern: trackPattern)
            let artistRegex = try NSRegularExpression(pattern: artistPattern)
            
            let trackMatches = trackRegex.matches(in: html, range: NSRange(html.startIndex..., in: html))
            let artistMatches = artistRegex.matches(in: html, range: NSRange(html.startIndex..., in: html))
            
            var tracks: [String] = []
            
            // Very basic heuristic: pair tracks with artists if possible, or just use track names
            for i in 0..<trackMatches.count {
                if let trackRange = Range(trackMatches[i].range(at: 1), in: html) {
                    let trackName = String(html[trackRange])
                    
                    // Try to find corresponding artist (heuristic)
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
    
    private func scanForNewFiles(in directory: URL, modelContext: ModelContext) {
        Task {
            let files = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            if let newFile = files?.sorted(by: { $0.contentModificationDate ?? .distantPast > $1.contentModificationDate ?? .distantPast }).first {
                try? await MetadataParser.parseID3Tags(from: newFile, context: modelContext)
            }
        }
    }
}

extension URL {
    var contentModificationDate: Date? {
        return (try? resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
    }
}
