import Foundation

class MetadataServiceWin {
    static let shared = MetadataServiceWin()
    
    struct TrackInfo {
        var title: String
        var artist: String
        var album: String
        var duration: Double
    }
    
    func parseFile(at path: String) -> TrackInfo {
        print("Windows: Parsing metadata for \(path)")
        
        // В Windows это реализуется через Windows.Storage.FileProperties
        // let file = try await StorageFile.getFileFromPathAsync(path)
        // let properties = try await file.musicProperties.getMusicPropertiesAsync()
        
        return TrackInfo(
            title: "Unknown Track", // properties.title
            artist: "Unknown Artist", // properties.artist
            album: "Unknown Album", // properties.album
            duration: 0.0 // properties.duration.seconds
        )
    }
}
