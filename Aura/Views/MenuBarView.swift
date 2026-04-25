import SwiftUI

struct MenuBarView: View {
    @Bindable var audioPlayer = AudioPlayerService.shared
    
    var body: some View {
        VStack(spacing: 16) {
            if let track = audioPlayer.currentTrack {
                // Track Info
                HStack(spacing: 12) {
                    ZStack {
                        if let art = track.album?.coverArt, let img = NSImage(data: art) {
                            Image(nsImage: img)
                                .resizable()
                        } else {
                            Color.accentColor.opacity(0.1)
                                .overlay(Image(systemName: "music.note"))
                        }
                    }
                    .frame(width: 44, height: 44)
                    .cornerRadius(8)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(track.title)
                            .font(.system(size: 13, weight: .bold))
                            .lineLimit(1)
                        Text(track.album?.artist?.name ?? "Unknown Artist")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                }
                
                // Controls
                HStack(spacing: 20) {
                    Button(action: { audioPlayer.previousTrack() }) {
                        Image(systemName: "backward.fill")
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { audioPlayer.togglePlayPause() }) {
                        Image(systemName: audioPlayer.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 24))
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { audioPlayer.nextTrack() }) {
                        Image(systemName: "forward.fill")
                    }
                    .buttonStyle(.plain)
                }
                
                // Volume
                HStack {
                    Image(systemName: "speaker.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Slider(value: $audioPlayer.volume, in: 0...1)
                        .controlSize(.mini)
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "waveform")
                        .font(.system(size: 24))
                        .foregroundColor(.secondary)
                    Text("No Track Playing")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .frame(height: 100)
            }
            
            Divider()
            
            // System Actions
            VStack(spacing: 4) {
                Button(action: { 
                    NSApp.activate(ignoringOtherApps: true)
                    // Logic to bring main window to front
                    if let window = NSApp.windows.first {
                        window.makeKeyAndOrderFront(nil)
                    }
                }) {
                    HStack {
                        Text("Show Aura")
                        Spacer()
                        Text("⌘A").foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)
                .padding(.vertical, 4)
                
                Button(action: { NSApplication.shared.terminate(nil) }) {
                    HStack {
                        Text("Quit")
                        Spacer()
                        Text("⌘Q").foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)
                .padding(.vertical, 4)
            }
        }
        .padding(16)
        .frame(width: 260)
        .background(VisualEffectView(material: .popover, blendingMode: .withinWindow))
    }
}
