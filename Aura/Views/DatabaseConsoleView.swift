import SwiftUI
import SwiftData
import Foundation

enum ConsoleSidebarItem: Hashable {
    case entity(String)
    case table(String)
}

struct DatabaseConsoleView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var sidebarSelection: ConsoleSidebarItem? = .entity("Tracks")
    @State private var queryText: String = ""
    @State private var resultsCount: Int = 0
    @State private var isSQLMode = false
    @State private var sqlResults: [[String: String]] = []
    @State private var sqlStatus: String = ""
    @State private var schemaTables: [String] = []
    @State private var tableInfo: [[String: String]] = []
    @State private var foreignKeys: [[String: String]] = []
    @State private var rawTableData: [[String: String]] = []
    @State private var dbFileSize: String = "Unknown"
    
    let entities = ["Artists", "Albums", "Tracks", "Playlists", "UserActivity"]
    
    var body: some View {
        NavigationSplitView {
            sidebarView
        } detail: {
            detailView
        }
    }
    
    private var sidebarView: some View {
        List(selection: $sidebarSelection) {
            Section("SwiftData Entities (Mapped)") {
                ForEach(entities, id: \.self) { entity in
                    NavigationLink(value: ConsoleSidebarItem.entity(entity)) {
                        Label(entity, systemImage: entityIcon(for: entity))
                    }
                }
            }
            
            Section("Physical SQLite Tables (Raw)") {
                ForEach(schemaTables, id: \.self) { table in
                    NavigationLink(value: ConsoleSidebarItem.table(table)) {
                        Text(table)
                            .font(.system(.caption, design: .monospaced))
                    }
                }
            }
        }
        .navigationTitle("Aura Engine DB")
        .onAppear { 
            refreshSchema()
            updateDBInfo()
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                Divider()
                HStack {
                    Text("Size: \(dbFileSize)")
                    Spacer()
                    Toggle("SQL Console", isOn: $isSQLMode)
                        .toggleStyle(.checkbox)
                }
                .padding(8)
                .font(.caption2.monospaced())
            }
            .background(.thinMaterial)
        }
    }
    
    private var detailView: some View {
        VStack(spacing: 0) {
            if isSQLMode {
                sqlConsoleView
            } else {
                switch sidebarSelection {
                case .entity(let entity):
                    standardDataView(for: entity)
                case .table(let table):
                    schemaInspectorView(for: table)
                case .none:
                    ContentUnavailableView("Select an Item", systemImage: "sidebar.left")
                }
            }
        }
        .onChange(of: sidebarSelection) { _, newValue in
            if case .table(let table) = newValue {
                fetchTableSchema(table)
            }
        }
    }
    
    private var sqlConsoleView: some View {
        VStack(spacing: 0) {
            // SQL Input
            VStack(alignment: .leading) {
                Text("SQL CONSOLE")
                    .font(.caption.bold())
                    .foregroundColor(.accentColor)
                
                TextEditor(text: $queryText)
                    .font(.system(.body, design: .monospaced))
                    .frame(height: 100)
                    .padding(4)
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(4)
                
                HStack {
                    Button("Run Query (SELECT)") { runSQL(isSelect: true) }
                        .keyboardShortcut(.return, modifiers: .command)
                    Button("Execute (UPDATE/INSERT)") { runSQL(isSelect: false) }
                    Spacer()
                    Text(sqlStatus)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color.black.opacity(0.1))
            
            // SQL Results Table
            if !sqlResults.isEmpty {
                let columns = Array(sqlResults.first?.keys.sorted() ?? [])
                
                ScrollView([.horizontal, .vertical]) {
                    VStack(alignment: .leading, spacing: 0) {
                        // Header
                        HStack(spacing: 0) {
                            ForEach(columns, id: \.self) { col in
                                Text(col)
                                    .font(.caption.bold())
                                    .frame(width: 150, alignment: .leading)
                                    .padding(8)
                                    .background(Color.secondary.opacity(0.2))
                                    .border(Color.secondary.opacity(0.1))
                            }
                        }
                        
                        // Rows
                        ForEach(0..<sqlResults.count, id: \.self) { rowIndex in
                            HStack(spacing: 0) {
                                ForEach(columns, id: \.self) { col in
                                    Text(sqlResults[rowIndex][col] ?? "NULL")
                                        .font(.system(size: 11, design: .monospaced))
                                        .frame(width: 150, alignment: .leading)
                                        .padding(8)
                                        .border(Color.secondary.opacity(0.05))
                                }
                            }
                            .background(rowIndex % 2 == 0 ? Color.clear : Color.white.opacity(0.03))
                        }
                    }
                }
            } else {
                ContentUnavailableView("No Results", systemImage: "terminal", description: Text("Enter a SQL query and press Cmd+Enter"))
            }
        }
    }
    
    private func standardDataView(for entity: String) -> some View {
        VStack(spacing: 0) {
            // Query Bar
            HStack {
                Image(systemName: "terminal.fill")
                    .foregroundColor(.secondary)
                TextField("Search or filter data...", text: $queryText)
                    .textFieldStyle(.plain)
                    .font(.system(.body, design: .monospaced))
                
                if !queryText.isEmpty {
                    Button(action: { queryText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .buttonStyle(.plain)
                }
                
                Divider().frame(height: 16)
                
                Text("\(resultsCount) items")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.black.opacity(0.1))
            .overlay(Divider(), alignment: .bottom)
            
            // Data Table
            entityDataView(for: entity)
            
            // Bottom Info
            HStack {
                Text("SwiftData SQLite Store")
                    .font(.caption2)
                Spacer()
                Button("Copy DB Path") {
                    copyDBPath()
                }
                .buttonStyle(.borderless)
                .controlSize(.mini)
            }
            .padding(8)
            .background(Color.black.opacity(0.05))
        }
    }
    
    private func runSQL(isSelect: Bool) {
        guard let config = modelContext.container.configurations.first else { return }
        let dbPath = config.url.path
        
        let service = RawSQLService.shared
        if service.connect(to: dbPath) {
            if isSelect {
                sqlResults = service.executeQuery(queryText)
                sqlStatus = "Found \(sqlResults.count) rows"
            } else {
                sqlStatus = service.executeNonQuery(queryText)
                sqlResults = []
            }
        }
    }
    
    @ViewBuilder
    private func entityDataView(for entity: String) -> some View {
        switch entity {
        case "Artists": ArtistTableView(filter: queryText)
        case "Albums": AlbumTableView(filter: queryText)
        case "Tracks": TrackTableView(filter: queryText)
        default: 
            ContentUnavailableView("Table Empty", systemImage: "table.badge.more")
        }
    }
    
    private func entityIcon(for entity: String) -> String {
        switch entity {
        case "Artists": return "music.mic"
        case "Albums": return "square.stack"
        case "Tracks": return "music.note"
        case "Playlists": return "music.note.list"
        default: return "database"
        }
    }
    
    private func copyDBPath() {
        if let config = modelContext.container.configurations.first {
            let url = config.url
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(url.path, forType: .string)
        }
    }
    
    // MARK: - Schema Inspector Logic
    
    @ViewBuilder
    private func schemaInspectorView(for table: String) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Image(systemName: "square.stack.3d.down.right.fill")
                        .font(.title)
                        .foregroundColor(.accentColor)
                    VStack(alignment: .leading) {
                        Text(table)
                            .font(.title2.bold())
                        Text("Physical SQLite Table Structure")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.bottom)
                
                Text("COLUMNS & TYPES").font(.headline)
                schemaTable(data: tableInfo, columns: ["name", "type", "pk", "notnull"])
                
                if !foreignKeys.isEmpty {
                    Text("RELATIONSHIPS (FOREIGN KEYS)").font(.headline).padding(.top)
                    schemaTable(data: foreignKeys, columns: ["table", "from", "to"])
                }
            }
            .padding(30)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private func schemaTable(data: [[String: String]], columns: [String]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                ForEach(columns, id: \.self) { col in
                    Text(col.uppercased())
                        .font(.caption2.bold())
                        .frame(width: 120, alignment: .leading)
                        .padding(8)
                        .background(Color.secondary.opacity(0.2))
                }
            }
            
            ForEach(0..<data.count, id: \.self) { rowIndex in
                HStack(spacing: 0) {
                    ForEach(columns, id: \.self) { col in
                        Text(data[rowIndex][col] ?? "NULL")
                            .font(.system(size: 11, design: .monospaced))
                            .frame(width: 120, alignment: .leading)
                            .padding(8)
                            .border(Color.secondary.opacity(0.1))
                    }
                }
            }
        }
        .background(Color.black.opacity(0.05))
        .cornerRadius(8)
    }
    
    private func refreshSchema() {
        guard let config = modelContext.container.configurations.first else { return }
        let dbPath = config.url.path
        let service = RawSQLService.shared
        if service.connect(to: dbPath) {
            let results = service.executeQuery("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'Z_%'")
            schemaTables = results.compactMap { $0["name"] }.sorted()
        }
    }
    
    private func fetchTableSchema(_ table: String) {
        guard let config = modelContext.container.configurations.first else { return }
        let dbPath = config.url.path
        let service = RawSQLService.shared
        if service.connect(to: dbPath) {
            tableInfo = service.executeQuery("PRAGMA table_info(\(table))")
            foreignKeys = service.executeQuery("PRAGMA foreign_key_list(\(table))")
            rawTableData = service.executeQuery("SELECT * FROM \(table) LIMIT 10")
        }
    }
    
    private func updateDBInfo() {
        if let config = modelContext.container.configurations.first {
            let path = config.url.path
            if let attributes = try? FileManager.default.attributesOfItem(atPath: path),
               let size = attributes[.size] as? Int64 {
                dbFileSize = ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
            }
        }
    }
}

// MARK: - Specialized Entity Views

struct ArtistTableView: View {
    @Query private var artists: [Artist]
    var filter: String
    
    init(filter: String) {
        self.filter = filter
        let predicate = #Predicate<Artist> { artist in
            filter.isEmpty ? true : artist.name.contains(filter)
        }
        _artists = Query(filter: predicate, sort: \Artist.name)
    }
    
    var body: some View {
        Table(artists) {
            TableColumn("UUID") { artist in 
                Text(artist.uuid.uuidString.prefix(8)).font(.system(.caption, design: .monospaced)) 
            }
            TableColumn("Name", value: \.name)
            TableColumn("Genre") { artist in 
                Text(artist.genre.rawValue) 
            }
            TableColumn("Albums") { artist in 
                Text("\(artist.albums?.count ?? 0)") 
            }
        }
    }
}

struct AlbumTableView: View {
    @Query private var albums: [Album]
    var filter: String
    
    init(filter: String) {
        self.filter = filter
        let predicate = #Predicate<Album> { album in
            filter.isEmpty ? true : album.title.contains(filter)
        }
        _albums = Query(filter: predicate, sort: \Album.title)
    }
    
    var body: some View {
        Table(albums) {
            TableColumn("Title", value: \.title)
            TableColumn("Artist") { album in 
                Text(album.artist?.name ?? "N/A") 
            }
            TableColumn("Release") { album in
                Text(Calendar.current.component(.year, from: album.releaseDate).description)
            }
            TableColumn("Tracks") { album in 
                Text("\(album.tracks?.count ?? 0)") 
            }
        }
    }
}

struct TrackTableView: View {
    @Query private var tracks: [Track]
    var filter: String
    
    init(filter: String) {
        self.filter = filter
        let predicate = #Predicate<Track> { track in
            filter.isEmpty ? true : track.title.contains(filter)
        }
        _tracks = Query(filter: predicate, sort: \Track.title)
    }
    
    var body: some View {
        Table(tracks) {
            TableColumn("Title", value: \.title)
            TableColumn("BPM") { track in 
                Text("\(track.bpm)") 
            }
            TableColumn("Duration") { track in 
                Text(String(format: "%.2f", track.duration)) 
            }
            TableColumn("Plays") { track in 
                Text("\(track.playCount)") 
            }
            TableColumn("Lyrics") { track in 
                Image(systemName: track.lyrics != nil ? "checkmark.circle.fill" : "xmark.circle")
                    .foregroundColor(track.lyrics != nil ? .green : .secondary) 
            }
        }
    }
}
