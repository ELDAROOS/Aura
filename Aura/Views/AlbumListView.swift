import SwiftUI
import SwiftData

struct AlbumListView: View {
    @Query(sort: \Album.title) private var albums: [Album]
    
    var body: some View {
        List {
            if albums.isEmpty {
                ContentUnavailableView("No Albums Found", systemImage: "square.stack", description: Text("Your collection is empty."))
            } else {
                ForEach(albums) { album in
                    if let artist = album.artist {
                        NavigationLink(value: ContentView.SidebarSelection.artist(artist)) {
                            albumRow(album: album)
                        }
                    } else {
                        albumRow(album: album)
                    }
                }
            }
        }
        .navigationTitle("Albums")
    }
    
    @ViewBuilder
    private func albumRow(album: Album) -> some View {
        HStack(spacing: 12) {
            if let data = album.coverArt, let nsImage = NSImage(data: data) {
                Image(nsImage: nsImage)
                    .resizable()
                    .frame(width: 40, height: 40)
                    .cornerRadius(4)
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 40, height: 40)
                    .overlay(Image(systemName: "music.note").font(.system(size: 12)).foregroundColor(.secondary))
            }
            
            VStack(alignment: .leading) {
                Text(album.title)
                    .font(.headline)
                Text(album.artist?.name ?? "Unknown Artist")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
