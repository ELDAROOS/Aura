import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \Track.playCount, order: .reverse) private var recommendedTracks: [Track]
    @Query(sort: \Album.title) private var recentAlbums: [Album]
    
    let columns = [
        GridItem(.adaptive(minimum: 170, maximum: 200), spacing: 20)
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                // MARK: - Hero Section
                Text("Listen Now")
                    .font(.system(size: 34, weight: .bold))
                    .padding(.horizontal)
                
                // MARK: - AI Discovery Section
                if let topArtist = recommendedTracks.first?.album?.artist {
                    VStack(alignment: .leading, spacing: 15) {
                        HStack(spacing: 15) {
                            Image(systemName: "sparkles")
                                .font(.title)
                                .foregroundColor(.accentColor)
                            
                            VStack(alignment: .leading) {
                                Text("AI Discovery")
                                    .font(.headline)
                                Text("Based on your love for \(topArtist.name)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                // This could trigger a specific search in ImportView
                                // For now, we'll use a simple alert or print
                                print("Searching YouTube for more from \(topArtist.name)")
                            }) {
                                Text("Find More")
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.accentColor)
                                    .cornerRadius(20)
                                    .foregroundColor(.white)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding()
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(15)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.accentColor.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal)
                }
                
                // MARK: - Recommended Tracks (Grid)
                VStack(alignment: .leading, spacing: 15) {
                    Text("Recommended for You")
                        .font(.title2.bold())
                        .padding(.horizontal)
                    
                    LazyVGrid(columns: columns, spacing: 25) {
                        ForEach(recommendedTracks.prefix(8)) { track in
                            TrackCard(track: track)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // MARK: - Recent Albums (Horizontal or Grid)
                VStack(alignment: .leading, spacing: 15) {
                    Text("Recently Added")
                        .font(.title2.bold())
                        .padding(.horizontal)
                    
                    LazyVGrid(columns: columns, spacing: 25) {
                        ForEach(recentAlbums.prefix(4)) { album in
                            AlbumCard(album: album)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
}

// MARK: - Supporting Views
struct TrackCard: View {
    let track: Track
    @Bindable var audioPlayer = AudioPlayerService.shared
    
    var body: some View {
        Button(action: { audioPlayer.play(track: track) }) {
            VStack(alignment: .leading, spacing: 10) {
                ZStack(alignment: .bottomTrailing) {
                    if let artData = track.album?.coverArt, let img = NSImage(data: artData) {
                        Image(nsImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 170, height: 170)
                            .cornerRadius(12)
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.secondary.opacity(0.1))
                            .frame(width: 170, height: 170)
                            .overlay(Image(systemName: "music.note").font(.largeTitle).foregroundColor(.secondary))
                    }
                    
                    // Play Button Overlay on Hover (simplified)
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                        .padding(8)
                        .shadow(radius: 5)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(track.title)
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(1)
                    Text(track.album?.artist?.name ?? "Unknown Artist")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

struct AlbumCard: View {
    let album: Album
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let artData = album.coverArt, let img = NSImage(data: artData) {
                Image(nsImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 170, height: 170)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.secondary.opacity(0.1))
                    .frame(width: 170, height: 170)
                    .overlay(Image(systemName: "music.note").font(.largeTitle).foregroundColor(.secondary))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(album.title)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
                Text(album.artist?.name ?? "Unknown Artist")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
    }
}
