import Foundation
import SwiftData

class QueryEngine {
    static func recentArtists(in genre: Genre, context: ModelContext) throws -> [Artist] {
        let genreRaw = genre.rawValue
        
        // Live search/fetch with predicate
        let descriptor = FetchDescriptor<Artist>(
            predicate: #Predicate { artist in
                artist.genreValue == genreRaw
            }
        )
        
        let allArtists = try context.fetch(descriptor)
        let twoYearsAgo = Calendar.current.date(byAdding: .year, value: -2, to: Date()) ?? Date()
        
        return allArtists.filter { artist in
            artist.albums?.contains { $0.releaseDate >= twoYearsAgo } ?? false
        }
    }
    
    static func calculateTotalPlayTime(context: ModelContext) throws -> Float {
        let descriptor = FetchDescriptor<Track>()
        let allTracks = try context.fetch(descriptor)
        return allTracks.reduce(0) { $0 + ($1.duration * Float($1.playCount)) }
    }
}
