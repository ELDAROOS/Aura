import Foundation
import SwiftData

@Model
final class Artist {
    @Attribute(.unique) var name: String
    var uuid: UUID
    var originCountry: String
    var genreValue: String // String for predicate compatibility
    var biography: String
    @Attribute(.externalStorage) var profileImage: Data?
    
    var genre: Genre {
        get { Genre(rawValue: genreValue) ?? .other }
        set { genreValue = newValue.rawValue }
    }
    
    @Relationship(deleteRule: .cascade, inverse: \Album.artist)
    var albums: [Album]? = []
    
    init(uuid: UUID = UUID(), name: String, originCountry: String, genre: Genre, biography: String, profileImage: Data? = nil) {
        self.uuid = uuid
        self.name = name
        self.originCountry = originCountry
        self.genreValue = genre.rawValue
        self.biography = biography
        self.profileImage = profileImage
    }
}

enum Genre: String, Codable, CaseIterable {
    case rock = "Rock"
    case pop = "Pop"
    case jazz = "Jazz"
    case classical = "Classical"
    case hiphop = "Hip-Hop"
    case electronic = "Electronic"
    case other = "Other"
}
