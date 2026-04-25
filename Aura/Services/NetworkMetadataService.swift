import Foundation

struct ITunesArtistResult: Codable {
    let artistName: String?
    let primaryGenreName: String?
    let artistLinkUrl: String?
}

struct ITunesSearchResponse: Codable {
    let results: [ITunesArtistResult]
}

class NetworkMetadataService {
    static func fetchArtistInfo(name: String) async -> (biography: String, genre: String)? {
        let query = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        // Strategy 1: Specific Music Artist search
        if let info = await performSearch(query: query, entity: "musicArtist") {
            return info
        }
        
        // Strategy 2: Broader search if Strategy 1 fails
        print("DEBUG: Specific search failed, trying broader search for: \(name)")
        return await performSearch(query: query, entity: "all")
    }
    
    private static func performSearch(query: String, entity: String) async -> (biography: String, genre: String)? {
        guard let url = URL(string: "https://itunes.apple.com/search?term=\(query)&entity=\(entity)&limit=1") else { return nil }
        
        do {
            var request = URLRequest(url: url)
            request.setValue("AuraMusicApp/1.0", forHTTPHeaderField: "User-Agent")
            
            let (data, _) = try await URLSession.shared.data(for: request)
            let searchResponse = try JSONDecoder().decode(ITunesSearchResponse.self, from: data)
            
            if let result = searchResponse.results.first {
                print("DEBUG: Found result for entity '\(entity)': \(result.artistName ?? "Unknown")")
                let bio = "Verified on Apple Music. \nGenre: \(result.primaryGenreName ?? "Unknown"). \n\nLink: \(result.artistLinkUrl ?? "")"
                return (bio, result.primaryGenreName ?? "Other")
            }
        } catch {
            print("DEBUG: ERROR - Request for entity '\(entity)' failed: \(error.localizedDescription)")
        }
        return nil
    }
}
