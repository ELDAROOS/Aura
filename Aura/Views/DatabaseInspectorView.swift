import SwiftUI
import SwiftData

struct DatabaseInspectorView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var artists: [Artist]
    @Query private var albums: [Album]
    @Query private var tracks: [Track]
    
    @State private var dbSize: String = "Calculating..."
    
    var body: some View {
        Form {
            Section("Statistics") {
                LabeledContent("Artists", value: "\(artists.count)")
                LabeledContent("Albums", value: "\(albums.count)")
                LabeledContent("Tracks", value: "\(tracks.count)")
            }
            
            Section("Storage") {
                LabeledContent("Size on Disk", value: dbSize)
            }
        }
        .padding()
        .onAppear {
            calculateDBSize()
        }
    }
    
    private func calculateDBSize() {
        if let storeURL = modelContext.container.configurations.first?.url {
            if let attributes = try? FileManager.default.attributesOfItem(atPath: storeURL.path),
               let size = attributes[.size] as? NSNumber {
                let formatter = ByteCountFormatter()
                formatter.allowedUnits = [.useMB, .useKB]
                formatter.countStyle = .file
                dbSize = formatter.string(fromByteCount: size.int64Value)
            } else {
                dbSize = "Unknown"
            }
        }
    }
}
