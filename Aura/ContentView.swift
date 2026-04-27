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
    @State private var isFileImporterPresented = false
    @State private var isImportPresented = false
    @State private var searchText = ""
    
    enum SidebarSelection: Hashable {
        case home
        case artistList
        case playlist(SmartPlaylistType)
        case artist(Artist)
    }
    
    enum SmartPlaylistType: String, CaseIterable, Identifiable {
        case recentlyAdded = "Recently Added"
        case favorites = "Most Played"
        
        var id: String { self.rawValue }
        var icon: String {
            switch self {
            case .recentlyAdded: return "clock.badge.checkmark"
            case .favorites: return "star.fill"
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
        ZStack {
            NavigationSplitView {
                // COLUMN 1: SIDEBAR
                List(selection: $sidebarSelection) {
                    if searchText.isEmpty {
                        Section("Discovery") {
                            NavigationLink(value: SidebarSelection.home) {
                                Label("Home", systemImage: "house.fill")
                            }
                            
                            ForEach(SmartPlaylistType.allCases) { playlist in
                                NavigationLink(value: SidebarSelection.playlist(playlist)) {
                                    Label(LocalizedStringKey(playlist.rawValue), systemImage: playlist.icon)
                                }
                            }
                            
                            Button(action: { isImportPresented.toggle() }) {
                                Label("Import from Link", systemImage: "link.badge.plus")
                            }
                            .buttonStyle(.plain)
                            .padding(.vertical, 4)
                        }
                        
                        Section("Library") {
                            NavigationLink(value: SidebarSelection.artistList) {
                                Label("Artists", systemImage: "music.mic")
                            }
                            
                            ForEach(filteredArtists) { artist in
                                NavigationLink(value: SidebarSelection.artist(artist)) {
                                    Label(artist.name, systemImage: "music.note")
                                }
                            }
                        }
                    } else {
                        searchResultsSection
                    }
                }
                .listStyle(SidebarListStyle())
                .navigationTitle("Aura")
                .searchable(text: $searchText, placement: .sidebar, prompt: Text("Search", comment: "Search prompt"))
            } detail: {
                // COLUMN 2: MAIN CONTENT (Merged)
                mainDetailView
            }
            .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                handleDrop(providers: providers)
            }
            .sheet(isPresented: $isSettingsPresented) {
                SettingsView()
            }
            .sheet(isPresented: $isImportPresented) {
                ImportView()
            }
            .inspector(isPresented: $isInspectorPresented) {
                DatabaseInspectorView()
                    .inspectorColumnWidth(min: 200, ideal: 250, max: 300)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { isFileImporterPresented.toggle() }) {
                        Label("Add Music", systemImage: "plus")
                    }
                }
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
            .fileImporter(
                isPresented: $isFileImporterPresented,
                allowedContentTypes: [.audio, .mp3, .mpeg4Audio],
                allowsMultipleSelection: true
            ) { result in
                switch result {
                case .success(let urls):
                    Task {
                        for url in urls {
                            if url.startAccessingSecurityScopedResource() {
                                try? await MetadataParser.parseID3Tags(from: url, context: modelContext)
                                url.stopAccessingSecurityScopedResource()
                            }
                        }
                    }
                case .failure(let error):
                    print("Error picking files: \(error.localizedDescription)")
                }
            }
            .safeAreaInset(edge: .bottom) {
                MiniPlayerView()
            }
            
            // Full Screen Now Playing Overlay
            if audioPlayer.isNowPlayingVisible {
                NowPlayingView()
                    .transition(.move(edge: .bottom))
                    .zIndex(100)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: audioPlayer.isNowPlayingVisible)
        .onAppear {
            if sidebarSelection == nil {
                sidebarSelection = .home
            }
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
    private var mainDetailView: some View {
        if let sidebarSelection {
            switch sidebarSelection {
            case .home:
                HomeView()
            case .artistList:
                ArtistListView()
            case .artist(let artist):
                ArtistDetailView(artist: artist)
            case .playlist(let playlist):
                let smartTracks = getSmartTracks(for: playlist)
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 20) {
                        Image(systemName: playlist.icon)
                            .font(.system(size: 60))
                            .foregroundColor(.accentColor)
                            .frame(width: 120, height: 120)
                            .background(RoundedRectangle(cornerRadius: 15).fill(Color.accentColor.opacity(0.1)))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(LocalizedStringKey(playlist.rawValue))
                                .font(.system(size: 34, weight: .bold))
                            Text("Automatically curated based on your library.")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(30)
                    
                    TrackListView(tracks: smartTracks)
                }
            }
        } else {
            ContentUnavailableView("Welcome to Aura", systemImage: "music.note", description: Text("Select something from the sidebar to start listening."))
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
        }
    }
}
