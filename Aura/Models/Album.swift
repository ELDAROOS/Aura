import Foundation
import SwiftData

@Model
final class Album {
    var uuid: UUID
    var title: String
    var releaseDate: Date
    var label: String
    var typeValue: String
    @Attribute(.externalStorage) var coverArt: Data?
    
    var type: AlbumType {
        get { AlbumType(rawValue: typeValue) ?? .lp }
        set { typeValue = newValue.rawValue }
    }
    
    var artist: Artist?
    
    @Relationship(deleteRule: .cascade, inverse: \Track.album)
    var tracks: [Track]? = []
    
    init(uuid: UUID = UUID(), title: String, releaseDate: Date, label: String, type: AlbumType, coverArt: Data? = nil) {
        // Validation: year >= 1860
        let calendar = Calendar.current
        let year = calendar.component(.year, from: releaseDate)
        if year < 1860 {
            var dateComponents = calendar.dateComponents([.month, .day, .hour, .minute, .second], from: releaseDate)
            dateComponents.year = 1860
            self.releaseDate = calendar.date(from: dateComponents) ?? releaseDate
        } else {
            self.releaseDate = releaseDate
        }
        
        self.uuid = uuid
        self.title = title
        self.label = label
        self.typeValue = type.rawValue
        self.coverArt = coverArt
    }
}

enum AlbumType: String, Codable, CaseIterable {
    case single = "Single"
    case ep = "EP"
    case lp = "LP"
}
