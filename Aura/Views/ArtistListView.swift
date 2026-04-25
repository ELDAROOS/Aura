import SwiftUI
import SwiftData

struct ArtistListView: View {
    @Query(sort: \Artist.name) private var artists: [Artist]
    @AppStorage("artist_view_style") private var artistViewStyle: String = "list"
    
    let columns = [
        GridItem(.adaptive(minimum: 140, maximum: 180), spacing: 20)
    ]
    
    var body: some View {
        Group {
            if artistViewStyle == "grid" {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 30) {
                        ForEach(artists) { artist in
                            NavigationLink(value: ContentView.SidebarSelection.artist(artist)) {
                                ArtistGridItem(artist: artist)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            } else {
                List {
                    if artists.isEmpty {
                        ContentUnavailableView("No Artists Found", systemImage: "music.mic", description: Text("Add some music to see artists here."))
                    } else {
                        ForEach(artists) { artist in
                            NavigationLink(value: ContentView.SidebarSelection.artist(artist)) {
                                ArtistListRow(artist: artist)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Artists")
    }
}

// MARK: - Supporting Views
struct ArtistListRow: View {
    let artist: Artist
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                if let artData = artist.albums?.first(where: { $0.coverArt != nil })?.coverArt, let nsImage = NSImage(data: artData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.accentColor.opacity(0.1))
                        .frame(width: 32, height: 32)
                    Image(systemName: "person.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.accentColor)
                }
            }
            
            VStack(alignment: .leading) {
                Text(artist.name)
                    .font(.headline)
                Text("\(artist.albums?.count ?? 0) Albums")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ArtistGridItem: View {
    let artist: Artist
    
    var body: some View {
        VStack(spacing: 15) {
            ZStack {
                if let artData = artist.albums?.first(where: { $0.coverArt != nil })?.coverArt, let nsImage = NSImage(data: artData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
                } else {
                    Circle()
                        .fill(Color.secondary.opacity(0.1))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "person.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary.opacity(0.5))
                }
            }
            
            VStack(spacing: 4) {
                Text(artist.name)
                    .font(.system(size: 16, weight: .bold))
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                
                Text("\(artist.albums?.count ?? 0) Albums")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
