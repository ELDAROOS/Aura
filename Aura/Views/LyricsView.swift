import SwiftUI

struct LyricsView: View {
    var track: Track
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Dynamic Background based on Album Art
            ZStack {
                if let artData = track.album?.coverArt, let nsImage = NSImage(data: artData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .blur(radius: 80)
                        .scaleEffect(1.2)
                } else {
                    Color.black
                }
                
                Color.black.opacity(0.4)
            }
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack(alignment: .center) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    VStack(spacing: 2) {
                        Text(track.title)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                        Text(track.album?.artist?.name ?? "Unknown Artist")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    // Empty space for centering
                    Color.clear.frame(width: 24)
                }
                .padding(24)
                
                // Lyrics Scroll Area
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        if let lyrics = track.lyrics, !lyrics.isEmpty {
                            Text(lyrics)
                                .font(.system(size: 44, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.leading)
                                .lineSpacing(8)
                                .shadow(color: .black.opacity(0.3), radius: 10)
                        } else {
                            VStack(spacing: 20) {
                                Spacer(minLength: 100)
                                Image(systemName: "music.note.list")
                                    .font(.system(size: 60))
                                    .foregroundColor(.white.opacity(0.2))
                                Text("Lyrics not found")
                                    .font(.title2)
                                    .bold()
                                    .foregroundColor(.white.opacity(0.4))
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(60)
                }
            }
        }
        .frame(minWidth: 600, minHeight: 700)
    }
}
