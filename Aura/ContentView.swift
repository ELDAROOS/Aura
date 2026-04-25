import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Artist.name) private var artists: [Artist]
    
    @State private var selectedArtist: Artist?
    @State private var selectedPlaylist: SmartPlaylistType?
    @State private var isInspectorPresented = false
    @State private var isSettingsPresented = false
    @State private var searchText = ""
    
    enum SmartPlaylistType: String, CaseIterable, Identifiable {
        case recentlyAdded = "Recently Added"
        case favorites = "Most Played"
        case rock = "Rock Essentials"
        case electronic = "Electronic Mix"
        
        var id: String { self.rawValue }
        var icon: String {
            switch self {
            case .recentlyAdded: return "clock.badge.checkmark"
            case .favorites: return "star.fill"
            case .rock: return "guitars.fill"
            case .electronic: return "bolt.horizontal.circle.fill"
            }
        }
    }
    
    var filteredArtists: [Artist] {
        if searchText.isEmpty {
            return artists
        } else {
            return artists.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var filteredTracks: [Track] {
        if searchText.isEmpty { return [] }
        let allTracks = artists.flatMap { $0.albums ?? [] }.flatMap { $0.tracks ?? [] }
        return allTracks.filter { 
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            ($0.album?.artist?.name.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    var body: some View {
        NavigationSplitView {
            List {
                if searchText.isEmpty {
                    Section("Discovery") {
                        ForEach(SmartPlaylistType.allCases) { playlist in
                            Button(action: { 
                                selectedPlaylist = playlist
                                selectedArtist = nil
                            }) {
                                Label(playlist.rawValue, systemImage: playlist.icon)
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(selectedPlaylist == playlist ? Color.accentColor : .primary)
                            .padding(.vertical, 2)
                        }
                    }
                    
                    Section("Library") {
                        ForEach(filteredArtists) { artist in
                            Button(action: { 
                                selectedArtist = artist
                                selectedPlaylist = nil
                            }) {
                                HStack {
                                    Image(systemName: "music.mic")
                                        .foregroundColor(.accentColor)
                                    Text(artist.name)
                                }
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(selectedArtist == artist ? Color.accentColor : .primary)
                            .padding(.vertical, 2)
                        }
                    }
                } else {
                    Section("Search Results") {
                        if !filteredArtists.isEmpty {
                            Text("Artists").font(.caption).foregroundColor(.secondary)
                            ForEach(filteredArtists) { artist in
                                Button(action: { selectedArtist = artist }) {
                                    Label(artist.name, systemImage: "music.mic")
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        if !filteredTracks.isEmpty {
                            Text("Songs").font(.caption).foregroundColor(.secondary).padding(.top, 8)
                            ForEach(filteredTracks.prefix(10)) { track in
                                Button(action: { audioPlayer.play(track: track, in: filteredTracks) }) {
                                    VStack(alignment: .leading) {
                                        Text(track.title).font(.system(size: 13))
                                        Text(track.album?.artist?.name ?? "").font(.system(size: 11)).foregroundColor(.secondary)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Aura")
            .searchable(text: $searchText, placement: .sidebar, prompt: "Artists, Songs...")
        } content: {
            if !searchText.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Searching for \"\(searchText)\"")
                        .font(.largeTitle).bold()
                    Text("Found \(filteredArtists.count) artists and \(filteredTracks.count) songs.")
                        .foregroundColor(.secondary)
                    Divider()
                }
                .padding()
            } else if let selectedArtist {
                ArtistDetailView(artist: selectedArtist)
            } else if let selectedPlaylist {
                VStack(alignment: .leading, spacing: 10) {
                    Label(selectedPlaylist.rawValue, systemImage: selectedPlaylist.icon)
                        .font(.largeTitle).bold()
                    Text("Automatically curated based on your library.")
                        .foregroundColor(.secondary)
                    Divider()
                }
                .padding()
            } else {
                Text("Select an item")
                    .foregroundStyle(.secondary)
            }
        } detail: {
            if !searchText.isEmpty {
                TrackListView(tracks: filteredTracks)
            } else if let selectedArtist, let albums = selectedArtist.albums {
                let tracks = albums.flatMap { $0.tracks ?? [] }
                TrackListView(tracks: tracks)
            } else if let selectedPlaylist {
                let smartTracks = getSmartTracks(for: selectedPlaylist)
                TrackListView(tracks: smartTracks)
            } else {
                ContentUnavailableView("No Selection", systemImage: "music.note.list", description: Text("Select an artist or search for music."))
            }
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            Task {
                for provider in providers {
                    if let item = try? await provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) as? URL {
                        try? await MetadataParser.parseID3Tags(from: item, context: modelContext)
                    }
                }
            }
            return true
        }
        .sheet(isPresented: $isSettingsPresented) {
            SettingsView()
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
            ToolbarItem {
                Button(action: { isSettingsPresented.toggle() }) {
                    Label("Settings", systemImage: "gearshape")
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            MiniPlayerView()
        }
    }
    
    private func getSmartTracks(for type: SmartPlaylistType) -> [Track] {
        let allTracks = artists.flatMap { $0.albums ?? [] }.flatMap { $0.tracks ?? [] }
        
        switch type {
        case .recentlyAdded:
            // For now, use UUID as a proxy for 'recently added' order, or just return first 20
            return Array(allTracks.prefix(20))
        case .favorites:
            return allTracks.sorted(by: { $0.playCount > $1.playCount }).prefix(20).map { $0 }
        case .rock:
            return allTracks.filter { $0.album?.artist?.genre == .rock }
        case .electronic:
            return allTracks.filter { $0.album?.artist?.genre == .electronic }
        }
    }
}
