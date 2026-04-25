import SwiftUI

struct TrackListView: View {
    var tracks: [Track]
    @Bindable var audioPlayer = AudioPlayerService.shared
    
    @State private var sortOrder = [KeyPathComparator(\Track.title)]
    
    var sortedTracks: [Track] {
        tracks.sorted(using: sortOrder)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Songs")
                    .font(.title2)
                    .bold()
                Spacer()
                Text("\(tracks.count) items")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 32)
            .padding(.top, 24)
            .padding(.bottom, 16)
            
            Table(sortedTracks, sortOrder: $sortOrder) {
                TableColumn("") { track in
                    Button(action: {
                        if audioPlayer.currentTrack?.uuid == track.uuid {
                            audioPlayer.togglePlayPause()
                        } else {
                            audioPlayer.play(track: track, in: sortedTracks)
                        }
                    }) {
                        Image(systemName: audioPlayer.currentTrack?.uuid == track.uuid && audioPlayer.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                            .background(Color.accentColor)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .opacity(audioPlayer.currentTrack?.uuid == track.uuid ? 1 : 0.8)
                }
                .width(30)
                
                TableColumn("Title", value: \.title) { track in
                    Text(track.title)
                        .font(.system(size: 13, weight: audioPlayer.currentTrack?.uuid == track.uuid ? .bold : .regular))
                        .foregroundColor(audioPlayer.currentTrack?.uuid == track.uuid ? .accentColor : .primary)
                }
                
                TableColumn("Album") { track in
                    Text(track.album?.title ?? "Unknown")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                TableColumn("Duration") { track in
                    Text(formatDuration(track.duration))
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .width(60)
                
                TableColumn("Plays") { track in
                    Text("\(track.playCount)")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .width(50)
            }
            .tableStyle(.inset)
            .padding(.horizontal, 16)
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private func formatDuration(_ seconds: Float) -> String {
        let min = Int(seconds) / 60
        let sec = Int(seconds) % 60
        return String(format: "%d:%02d", min, sec)
    }
}
