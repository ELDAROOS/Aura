import Foundation
import SwiftData

@Model
final class Track {
    var uuid: UUID
    var title: String
    var duration: Float // Requires duration > 0 validation before insert
    var bpm: Int
    var bitrate: Int
    var playCount: Int
    var isLossless: Bool
    var lyrics: String?
    var localFileName: String?
    
    var album: Album?
    
    @Relationship(inverse: \Playlist.tracks)
    var playlists: [Playlist]? = []
    
    // One-to-one to UserActivity
    @Relationship(deleteRule: .cascade)
    var activity: UserActivity?
    
    init(uuid: UUID = UUID(), title: String, duration: Float, bpm: Int, bitrate: Int, playCount: Int = 0, isLossless: Bool, lyrics: String? = nil, localFileName: String? = nil) {
        self.uuid = uuid
        self.title = title
        self.duration = max(0.1, duration) // ensure > 0
        self.bpm = bpm
        self.bitrate = bitrate
        self.playCount = playCount
        self.isLossless = isLossless
        self.lyrics = lyrics
        self.localFileName = localFileName
    }
}
