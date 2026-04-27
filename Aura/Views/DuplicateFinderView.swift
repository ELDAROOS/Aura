import SwiftUI
import SwiftData

struct DuplicateFinderView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let tracks: [Track]
    
    var duplicates: [String: [Track]] {
        Dictionary(grouping: tracks) { $0.title.lowercased() + ($0.album?.artist?.name.lowercased() ?? "") }
            .filter { $0.value.count > 1 }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Duplicate Finder")
                    .font(.headline)
                Spacer()
                Button("Close") { dismiss() }
            }
            .padding()
            .background(.ultraThinMaterial)
            
            if duplicates.isEmpty {
                ContentUnavailableView("No Duplicates Found", systemImage: "checkmark.circle.fill", description: Text("Your library is nice and clean."))
            } else {
                List {
                    ForEach(Array(duplicates.keys), id: \.self) { key in
                        Section(header: Text(duplicates[key]?.first?.title ?? "Unknown")) {
                            ForEach(duplicates[key] ?? []) { track in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(track.album?.title ?? "Unknown Album")
                                            .font(.subheadline)
                                        Text(track.localFileName ?? "No file")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Button(role: .destructive) {
                                        modelContext.delete(track)
                                    } label: {
                                        Image(systemName: "trash")
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
            }
        }
        .frame(width: 500, height: 400)
    }
}
