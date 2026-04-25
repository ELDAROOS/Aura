import Foundation
import SwiftData

@Model
final class Playlist {
    var uuid: UUID
    var name: String
    var playlistDescription: String
    var lastModified: Date
    
    var tracks: [Track]? = []
    
    init(uuid: UUID = UUID(), name: String, playlistDescription: String, lastModified: Date = Date()) {
        self.uuid = uuid
        self.name = name
        self.playlistDescription = playlistDescription
        self.lastModified = lastModified
    }
}
