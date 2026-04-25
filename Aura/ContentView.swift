import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Artist.name) private var artists: [Artist]
    @Bindable var audioPlayer = AudioPlayerService.shared
    
    @State private var sidebarSelection: SidebarSelection?
    @State private var isInspectorPresented = false
    @State private var isSettingsPresented = false
    @State private var searchText = ""
    
    enum SidebarSelection: Hashable {
        case playlist(SmartPlaylistType)
        case artist(Artist)
    }
    
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
            List(selection: $sidebarSelection) {
                if searchText.isEmpty {
                    Section("Discovery") {
                        ForEach(SmartPlaylistType.allCases) { playlist in
                            NavigationLink(value: SidebarSelection.playlist(playlist)) {
                                Label(playlist.rawValue, systemImage: playlist.icon)
                            }
                        }
                    }
                    
                    Section("Library") {
                        ForEach(filteredArtists) { artist in
                            NavigationLink(value: SidebarSelection.artist(artist)) {
                                Label(artist.name, systemImage: "music.mic")
                            }
                        }
                    }
                } else {
                    searchResultsSection
                }
            }
            .navigationTitle("Aura")
            .searchable(text: $searchText, placement: .sidebar, prompt: "Artists, Songs...")
        } content: {
            contentView
        } detail: {
            detailView
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            handleDrop(providers: providers)
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
    
    @ViewBuilder
    private var searchResultsSection: some View {
        Section("Search Results") {
            if !filteredArtists.isEmpty {
                Text("Artists").font(.caption).foregroundColor(.secondary)
                ForEach(filteredArtists) { artist in
                    Button(action: { sidebarSelection = .artist(artist) }) {
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
    
    @ViewBuilder
    private var contentView: some View {
        if !searchText.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Searching for \"\(searchText)\"")
                    .font(.largeTitle).bold()
                Text("Found \(filteredArtists.count) artists and \(filteredTracks.count) songs.")
                    .foregroundColor(.secondary)
                Divider()
            }
            .padding()
        } else if let sidebarSelection {
            switch sidebarSelection {
            case .artist(let artist):
                ArtistDetailView(artist: artist)
            case .playlist(let playlist):
                VStack(alignment: .leading, spacing: 10) {
                    Label(playlist.rawValue, systemImage: playlist.icon)
                        .font(.largeTitle).bold()
                    Text("Automatically curated based on your library.")
                        .foregroundColor(.secondary)
                    Divider()
                }
                .padding()
            }
        } else {
            Text("Select an item")
                .foregroundStyle(.secondary)
        }
    }
    
    @ViewBuilder
    private var detailView: some View {
        if !searchText.isEmpty {
            TrackListView(tracks: filteredTracks)
        } else if let sidebarSelection {
            switch sidebarSelection {
            case .artist(let artist):
                if let albums = artist.albums {
                    let tracks = albums.flatMap { $0.tracks ?? [] }
                    TrackListView(tracks: tracks)
                }
            case .playlist(let playlist):
                let smartTracks = getSmartTracks(for: playlist)
                TrackListView(tracks: smartTracks)
            }
        } else {
            ContentUnavailableView("No Selection", systemImage: "music.note.list", description: Text("Select an artist or search for music."))
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        Task {
            for provider in providers {
                if let item = try? await provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) as? URL {
                    try? await MetadataParser.parseID3Tags(from: item, context: modelContext)
                }
            }
        }
        return true
    }
    
    private func getSmartTracks(for type: SmartPlaylistType) -> [Track] {
        let allTracks = artists.flatMap { $0.albums ?? [] }.flatMap { $0.tracks ?? [] }
        
        switch type {
        case .recentlyAdded:
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
