import SwiftUI

struct ArtistDetailView: View {
    var artist: Artist
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(artist.name).font(.largeTitle).bold()
            HStack {
                Text(artist.genre.rawValue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.2))
                    .cornerRadius(8)
                Text("•")
                Text(artist.originCountry)
                    .foregroundStyle(.secondary)
            }
            Divider()
            Text("Biography").font(.headline)
            ScrollView {
                Text(artist.biography)
            }
        }
        .padding()
        .navigationTitle(artist.name)
    }
}
