import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Artist.name) private var artists: [Artist]
    
    @State private var selectedArtist: Artist?
    @State private var isInspectorPresented = false
    @State private var searchText = ""
    
    var filteredArtists: [Artist] {
        if searchText.isEmpty {
            return artists
        } else {
            return artists.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            List(filteredArtists, selection: $selectedArtist) { artist in
                NavigationLink(value: artist) {
                    Text(artist.name)
                }
            }
            .navigationTitle("Library")
            .searchable(text: $searchText, prompt: "Search artists...")
        } content: {
            if let selectedArtist {
                ArtistDetailView(artist: selectedArtist)
            } else {
                Text("Select an artist")
                    .foregroundStyle(.secondary)
            }
        } detail: {
            VStack(spacing: 0) {
                if let selectedArtist, let albums = selectedArtist.albums {
                    let tracks = albums.flatMap { $0.tracks ?? [] }
                    TrackListView(tracks: tracks)
                } else {
                    Spacer()
                    ContentUnavailableView("No Artist Selected", systemImage: "music.mic", description: Text("Select an artist from the library to view their albums."))
                    Spacer()
                }
                
                DropZoneView()
            }
        }
        .inspector(isPresented: $isInspectorPresented) {
            DatabaseInspectorView()
                .inspectorColumnWidth(min: 200, ideal: 250, max: 300)
        }
        .toolbar {
            ToolbarItem {
                Button(action: { isInspectorPresented.toggle() }) {
                    Label("Toggle Inspector", systemImage: "info.circle")
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            MiniPlayerView()
        }
    }
}
