import SwiftUI
import SwiftData

struct ArtistListView: View {
    @Query(sort: \Artist.name) private var artists: [Artist]
    
    var body: some View {
        List {
            if artists.isEmpty {
                ContentUnavailableView("No Artists Found", systemImage: "music.mic", description: Text("Add some music to see artists here."))
            } else {
                ForEach(artists) { artist in
                    NavigationLink(value: ContentView.SidebarSelection.artist(artist)) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.accentColor.opacity(0.1))
                                    .frame(width: 32, height: 32)
                                Image(systemName: "person.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.accentColor)
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
            }
        }
        .navigationTitle("Artists")
    }
}
