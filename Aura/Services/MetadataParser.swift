import Foundation
import SwiftData
import AVFoundation

class MetadataParser {
    static func parseID3Tags(from fileURL: URL, context: ModelContext) async throws {
        let isSecured = fileURL.startAccessingSecurityScopedResource()
        defer { if isSecured { fileURL.stopAccessingSecurityScopedResource() } }
        
        let asset = AVAsset(url: fileURL)
        let duration = try await asset.load(.duration)
        let durationSeconds = Float(CMTimeGetSeconds(duration))
        
        let metadata = try await asset.load(.metadata)
        
        var title = fileURL.deletingPathExtension().lastPathComponent
        var artistName = "Unknown Artist"
        var albumTitle = "Unknown Album"
        var coverArt: Data? = nil
        var lyrics: String? = nil
        var genreValue = "Other"
        
        for item in metadata {
            if let commonKey = item.commonKey?.rawValue {
                if let stringValue = try? await item.load(.stringValue) {
                    if commonKey == AVMetadataKey.commonKeyTitle.rawValue { title = stringValue }
                    else if commonKey == AVMetadataKey.commonKeyArtist.rawValue { artistName = stringValue }
                    else if commonKey == AVMetadataKey.commonKeyAlbumName.rawValue { albumTitle = stringValue }
                    else if commonKey == AVMetadataKey.commonKeyType.rawValue { genreValue = stringValue }
                }
                if commonKey == AVMetadataKey.commonKeyArtwork.rawValue {
                    if let data = try? await item.load(.dataValue) {
                        coverArt = data
                    }
                }
            }
            
            // Check for lyrics in identifier
            if let identifier = item.identifier?.rawValue {
                if identifier.lowercased().contains("lyric"), let stringValue = try? await item.load(.stringValue) {
                    lyrics = stringValue
                }
            }
        }
        
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let localFileName = UUID().uuidString + "." + fileURL.pathExtension
        let destinationURL = documentsDir.appendingPathComponent(localFileName)
        
        print("DEBUG: Copying file to: \(destinationURL.path)")
        do {
            try FileManager.default.copyItem(at: fileURL, to: destinationURL)
            print("DEBUG: File copied successfully.")
        } catch {
            print("DEBUG: ERROR - Failed to copy audio file: \(error.localizedDescription)")
        }
        
        await MainActor.run {
            // Find or Create Artist
            let artistFetch = FetchDescriptor<Artist>(predicate: #Predicate { $0.name == artistName })
            let existingArtists = try? context.fetch(artistFetch)
            let artist = existingArtists?.first ?? Artist(name: artistName, originCountry: "Unknown", genre: .other, biography: "")
            
            if artist.modelContext == nil {
                // If it's a known genre, try to set it
                if let parsedGenre = Genre(rawValue: genreValue) { artist.genre = parsedGenre }
                if artist.profileImage == nil { artist.profileImage = coverArt }
                context.insert(artist)
            } else if artist.profileImage == nil {
                artist.profileImage = coverArt // Update if missing
            }
            
            // Find or Create Album
            let albumFetch = FetchDescriptor<Album>(predicate: #Predicate { $0.title == albumTitle })
            let existingAlbums = try? context.fetch(albumFetch)
            let album = existingAlbums?.first(where: { $0.artist?.name == artistName }) ?? Album(title: albumTitle, releaseDate: Date(), label: "Unknown Label", type: .single)
            
            if album.modelContext == nil {
                album.artist = artist
                album.coverArt = coverArt
                context.insert(album)
            } else if album.coverArt == nil {
                album.coverArt = coverArt
            }
            
            // Create Track
            let track = Track(title: title, duration: durationSeconds > 0 ? durationSeconds : 1.0, bpm: 0, bitrate: 256, isLossless: true, lyrics: lyrics, localFileName: localFileName)
            track.album = album
            context.insert(track)
            
            try? context.save()
        }
    }
}
