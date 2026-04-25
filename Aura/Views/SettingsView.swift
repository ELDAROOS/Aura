import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingConfirmation = false
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Settings")
                    .font(.title2)
                    .bold()
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Database Management")
                    .font(.headline)
                
                Text("This will permanently remove all artists, albums, tracks and physical audio files from your library.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                Button(role: .destructive) {
                    showingConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "trash.fill")
                        Text("Clear Entire Library")
                    }
                    .padding(.horizontal, 8)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(12)
            
            Spacer()
            
            Text("Aura Music Database v1.0")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(24)
        .frame(width: 450, height: 350)
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
            // Delete all entities
            try modelContext.delete(model: Artist.self)
            try modelContext.delete(model: Album.self)
            try modelContext.delete(model: Track.self)
            try modelContext.delete(model: Playlist.self)
            try modelContext.delete(model: UserActivity.self)
            
            // Delete local files
            let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let files = try FileManager.default.contentsOfDirectory(at: documentsDir, includingPropertiesForKeys: nil)
            for file in files {
                // Avoid deleting the SQLite database itself while the context is active
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
