import SwiftUI
import SwiftData

struct ArtistDetailView: View {
    @Bindable var artist: Artist
    @State private var isUpdating = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Hero Header Area
                HStack(spacing: 24) {
                    ZStack {
                        if let imageData = artist.profileImage, let nsImage = NSImage(data: imageData) {
                            Image(nsImage: nsImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            LinearGradient(colors: [.accentColor, .accentColor.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                .overlay(
                                    Text(String(artist.name.prefix(1)))
                                        .font(.system(size: 48, weight: .bold))
                                        .foregroundColor(.white)
                                )
                        }
                    }
                    .frame(width: 140, height: 140)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(artist.name)
                            .font(.system(size: 36, weight: .bold))
                            .lineLimit(2)
                        
                        HStack(spacing: 12) {
                            Text(artist.genre.rawValue)
                                .font(.system(size: 13, weight: .semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color.accentColor.opacity(0.1)))
                                .foregroundColor(.accentColor)
                            
                            Text(artist.originCountry)
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        
                        Text("\(artist.albums?.count ?? 0) Albums")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            isUpdating = true
                            Task {
                                if let info = await NetworkMetadataService.fetchArtistInfo(name: artist.name) {
                                    await MainActor.run {
                                        artist.biography = info.biography
                                        // Save to database
                                        try? artist.modelContext?.save()
                                        isUpdating = false
                                    }
                                } else {
                                    await MainActor.run {
                                        alertMessage = "Could not find any info for '\(artist.name)' on Apple Music."
                                        showAlert = true
                                        isUpdating = false
                                    }
                                }
                            }
                        }) {
                            HStack {
                                if isUpdating {
                                    ProgressView().controlSize(.mini)
                                } else {
                                    Image(systemName: "globe")
                                }
                                Text(isUpdating ? "Searching..." : "Update Info from Web")
                            }
                            .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(isUpdating)
                    }
                }
                .padding(.top, 20)
                
                // Biography Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("About")
                        .font(.title3)
                        .bold()
                    
                    Text(artist.biography.isEmpty ? "No biography details available for this artist." : artist.biography)
                        .font(.system(size: 14))
                        .lineSpacing(6)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Divider()
            }
            .padding(32)
        }
        .background(Color(NSColor.windowBackgroundColor))
        .alert("Update Info", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
}
