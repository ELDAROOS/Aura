import SwiftUI
import SwiftData

struct AlbumListView: View {
    var albums: [Album]
    
    @State private var sortOrder = [KeyPathComparator(\Album.releaseDate)]
    
    var sortedAlbums: [Album] {
        albums.sorted(using: sortOrder)
    }
    
    var body: some View {
        Table(sortedAlbums, sortOrder: $sortOrder) {
            TableColumn("Title", value: \.title)
            TableColumn("Release Date", value: \.releaseDate) { album in
                Text(album.releaseDate, format: .dateTime.year())
            }
            TableColumn("Type", value: \.typeValue)
        }
        .navigationTitle("Albums")
    }
}
