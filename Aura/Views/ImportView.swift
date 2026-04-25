import SwiftUI
import SwiftData

struct ImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var urlString: String = ""
    @Bindable var downloadService = DownloadService.shared
    
    var body: some View {
        VStack(spacing: 25) {
            // Header
            HStack {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.accentColor)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Import Music")
                        .font(.title2.bold())
                    Text("Paste a Spotify or YouTube link below")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.top)
            
            // Input Field
            VStack(alignment: .leading, spacing: 8) {
                TextField("https://...", text: $urlString)
                    .textFieldStyle(.roundedBorder)
                    .controlSize(.large)
                    .onSubmit {
                        startDownload()
                    }
                
                Text("Supports Spotify tracks/playlists and YouTube videos/playlists.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // Status Section
            if downloadService.isDownloading {
                VStack(spacing: 12) {
                    ProgressView(value: downloadService.downloadProgress)
                        .progressViewStyle(.linear)
                    
                    Text(downloadService.currentStatus)
                        .font(.caption)
                        .foregroundColor(.accentColor)
                }
                .padding()
                .background(Color.accentColor.opacity(0.05))
                .cornerRadius(10)
            } else if !downloadService.currentStatus.isEmpty {
                Text(downloadService.currentStatus)
                    .font(.caption)
                    .foregroundColor(downloadService.currentStatus.contains("Error") ? .red : .green)
                    .padding(8)
            }
            
            Spacer()
            
            // Action Buttons
            HStack(spacing: 15) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                
                Button(action: startDownload) {
                    if downloadService.isDownloading {
                        ProgressView().controlSize(.small)
                    } else {
                        Text("Start Import")
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(urlString.isEmpty || downloadService.isDownloading)
            }
        }
        .padding(30)
        .frame(width: 500, height: 350)
    }
    
    private func startDownload() {
        guard !urlString.isEmpty else { return }
        downloadService.download(url: urlString, modelContext: modelContext)
    }
}
