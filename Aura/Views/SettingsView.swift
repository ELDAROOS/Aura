import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("app_language") private var appLanguage: String = "system"
    @AppStorage("app_theme") private var appTheme: String = "system"
    @AppStorage("artist_view_style") private var artistViewStyle: String = "list"
    @State private var showingConfirmation = false
    @State private var showingConsole = false
    
    let languages = [
        ("system", "System Default", "🖥️"),
        ("en", "English", "🇺🇸"),
        ("ru", "Русский", "🇷🇺"),
        ("kk", "Қазақ", "🇰🇿")
    ]
    
    let themes = [
        ("system", "System", "🖥️"),
        ("light", "Light", "☀️"),
        ("dark", "Dark", "🌙")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // macOS-style Header
            HStack {
                Text("Settings")
                    .font(.headline)
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.return, modifiers: .command)
            }
            .padding()
            .background(.ultraThinMaterial)
            
            Form {
                Section("Appearance & Language") {
                    Picker(selection: $appLanguage) {
                        ForEach(languages, id: \.0) { lang in
                            Text("\(lang.2) \(lang.1)").tag(lang.0)
                        }
                    } label: {
                        Label("Language", systemImage: "globe")
                    }
                    
                    Picker(selection: $appTheme) {
                        ForEach(themes, id: \.0) { theme in
                            Text("\(theme.2) \(theme.1)").tag(theme.0)
                        }
                    } label: {
                        Label("Theme", systemImage: "paintbrush.fill")
                    }
                }
                
                Section("Library View") {
                    Picker(selection: $artistViewStyle) {
                        Text("Classic List").tag("list")
                        Text("Modern Grid").tag("grid")
                    } label: {
                        Label("Artists Style", systemImage: "square.grid.2x2")
                    }
                    .pickerStyle(.inline)
                }
                
                Section("Developer") {
                    Button(action: { showingConsole = true }) {
                        Label("Open Database Console", systemImage: "terminal.fill")
                    }
                    .buttonStyle(.link)
                    .sheet(isPresented: $showingConsole) {
                        DatabaseConsoleView()
                            .frame(minWidth: 800, minHeight: 600)
                    }
                }
                
                Section(header: Text("Database Management"), footer: Text("This action cannot be undone and will delete all stored music files.")) {
                    Button(role: .destructive) {
                        showingConfirmation = true
                    } label: {
                        Label("Clear Entire Library", systemImage: "trash.fill")
                            .foregroundColor(.red)
                    }
                }
                
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 4) {
                            Text("Aura Music Database")
                                .font(.caption.bold())
                            Text("Version 1.0.0 (Build 2026)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 10)
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 480, height: 420)
        .confirmationDialog("Are you sure you want to clear your entire library?", isPresented: $showingConfirmation) {
            Button("Clear All Data", role: .destructive) {
                clearLibrary()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action cannot be undone and will delete all stored music files.")
        }
    }
    
    private func clearLibrary() {
        do {
            try modelContext.delete(model: Artist.self)
            try modelContext.delete(model: Album.self)
            try modelContext.delete(model: Track.self)
            try modelContext.delete(model: Playlist.self)
            try modelContext.delete(model: UserActivity.self)
            
            let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let files = try FileManager.default.contentsOfDirectory(at: documentsDir, includingPropertiesForKeys: nil)
            for file in files {
                let fileName = file.lastPathComponent
                if !fileName.contains("default.store") && !fileName.contains("sqlite") {
                    try? FileManager.default.removeItem(at: file)
                }
            }
            
            try modelContext.save()
            dismiss()
        } catch {
            print("DEBUG: ERROR - Failed to clear library: \(error.localizedDescription)")
        }
    }
}
