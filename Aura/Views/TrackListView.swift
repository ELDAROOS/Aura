import SwiftUI

struct TrackListView: View {
    var tracks: [Track]
    var audioPlayer = AudioPlayerService.shared
    
    @State private var sortOrder = [KeyPathComparator(\Track.title)]
    
    var sortedTracks: [Track] {
        tracks.sorted(using: sortOrder)
    }
    
    var body: some View {
        Table(sortedTracks, sortOrder: $sortOrder) {
            TableColumn("") { track in
                Button(action: {
                    if audioPlayer.currentTrack?.uuid == track.uuid {
                        audioPlayer.togglePlayPause()
                    } else {
                        audioPlayer.play(track: track)
                    }
                }) {
                    Image(systemName: audioPlayer.currentTrack?.uuid == track.uuid && audioPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .foregroundColor(.accentColor)
                        .font(.title2)
                }
                .buttonStyle(.plain)
            }
            .width(30)
            
            TableColumn("Title", value: \.title)
            
            TableColumn("Duration") { track in
                Text(formatDuration(track.duration))
            }
            .width(60)
            
            TableColumn("Bitrate") { track in
                Text("\(track.bitrate) kbps")
            }
            .width(80)
            
            TableColumn("Plays") { track in
                Text("\(track.playCount)")
            }
            .width(60)
        }
        .navigationTitle("Tracks")
    }
    
    private func formatDuration(_ seconds: Float) -> String {
        let min = Int(seconds) / 60
        let sec = Int(seconds) % 60
        return String(format: "%d:%02d", min, sec)
    }
}
