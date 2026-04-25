import Foundation
import SwiftData

struct SeedPayload: Decodable {
    let artists: [SeedArtist]
}

struct SeedArtist: Decodable {
    let name: String
    let originCountry: String
    let genre: String
    let biography: String
    let albums: [SeedAlbum]
}

struct SeedAlbum: Decodable {
    let title: String
    let releaseDate: String // ISO8601
    let label: String
    let type: String
    let tracks: [SeedTrack]
}

struct SeedTrack: Decodable {
    let title: String
    let duration: Float
    let bpm: Int
    let bitrate: Int
    let isLossless: Bool
}

class SeedEngine {
    static func seed(from url: URL, context: ModelContext) throws {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let payload = try decoder.decode(SeedPayload.self, from: data)
        
        for artistData in payload.artists {
            let genre = Genre(rawValue: artistData.genre) ?? .other
            let artist = Artist(name: artistData.name, originCountry: artistData.originCountry, genre: genre, biography: artistData.biography)
            context.insert(artist)
            
            let isoFormatter = ISO8601DateFormatter()
            
            for albumData in artistData.albums {
                let type = AlbumType(rawValue: albumData.type) ?? .lp
                let date = isoFormatter.date(from: albumData.releaseDate) ?? Date()
                let album = Album(title: albumData.title, releaseDate: date, label: albumData.label, type: type)
                album.artist = artist
                context.insert(album)
                
                for trackData in albumData.tracks {
                    let track = Track(title: trackData.title, duration: trackData.duration, bpm: trackData.bpm, bitrate: trackData.bitrate, isLossless: trackData.isLossless)
                    track.album = album
                    context.insert(track)
                }
            }
        }
        try context.save()
    }
}
