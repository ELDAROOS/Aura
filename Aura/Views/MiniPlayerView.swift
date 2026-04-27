import SwiftUI

struct MiniPlayerView: View {
    private var audioPlayer: AudioPlayerService { AudioPlayerService.shared }
    @State private var showingLyrics = false
    @State private var showingQueue = false
    
    var body: some View {
        @Bindable var player = AudioPlayerService.shared
        
        if let track = player.currentTrack {
            VStack(spacing: 0) {
                // Interactive Progress Slider
                VStack(spacing: -8) {
                    Slider(value: Binding(
                        get: { player.currentTime },
                        set: { player.seek(to: $0) }
                    ), in: 0...(player.duration > 0 ? player.duration : 1))
                    .controlSize(.small)
                    .accentColor(.accentColor)
                    
                    HStack {
                        Text(player.timeString)
                        Spacer()
                        Text(player.totalTimeString)
                    }
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
                    .opacity(0.8)
                }
                .padding(.horizontal, 0)
                .frame(height: 12)
                
                HStack(spacing: 0) {
                    // Left Side: Artwork & Metadata
                    HStack(spacing: 12) {
                        Button(action: { player.isNowPlayingVisible = true }) {
                            ZStack {
                                if let coverArt = track.album?.coverArt, let nsImage = NSImage(data: coverArt) {
                                    Image(nsImage: nsImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } else {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.gray.opacity(0.2))
                                        .overlay(Image(systemName: "music.note").foregroundColor(.secondary))
                                }
                            }
                            .frame(width: 48, height: 48)
                            .cornerRadius(6)
                            .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                        }
                        .buttonStyle(.plain)
                        .help("Show Now Playing")
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text(track.title)
                                .font(.system(size: 13, weight: .bold))
                                .lineLimit(1)
                            Text(track.album?.artist?.name ?? "Unknown Artist")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        .frame(width: 180, alignment: .leading)
                    }
                    .padding(.leading, 20)
                    
                    Spacer()
                    
                    // Center: Playback Controls
                    HStack(spacing: 24) {
                        Button(action: { player.isShuffle.toggle() }) {
                            Image(systemName: "shuffle")
                                .font(.system(size: 14))
                                .foregroundColor(player.isShuffle ? .accentColor : .secondary)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: { player.previousTrack() }) {
                            Image(systemName: "backward.fill")
                                .font(.system(size: 18))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .foregroundColor(.primary.opacity(0.8))
                        
                        Button(action: { player.togglePlayPause() }) {
                            ZStack {
                                Circle()
                                    .fill(Color.primary.opacity(0.05))
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: 20))
                                    .offset(x: player.isPlaying ? 0 : 1)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .foregroundColor(.primary)
                        
                        Button(action: { player.nextTrack() }) {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 18))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .foregroundColor(.primary.opacity(0.8))
                        
                        Button(action: { /* Repeat logic */ }) {
                            Image(systemName: "repeat")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    Spacer()
                    
                    // Right Side: Volume & Extra Controls
                    HStack(spacing: 15) {
                        Image(systemName: player.volume == 0 ? "speaker.slash.fill" : "speaker.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        
                        Slider(value: $player.volume, in: 0...1)
                            .controlSize(.mini)
                            .frame(width: 80)
                            .accentColor(.secondary)
                        
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        
                        Button(action: { showingLyrics.toggle() }) {
                            Image(systemName: "quote.bubble")
                                .font(.system(size: 14))
                                .foregroundColor(track.lyrics != nil ? .accentColor : .secondary)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .sheet(isPresented: $showingLyrics) {
                            LyricsView(track: track)
                        }
                        
                        Button(action: { showingQueue.toggle() }) {
                            Image(systemName: "list.bullet")
                                .font(.system(size: 14))
                                .foregroundColor(showingQueue ? .accentColor : .secondary)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .popover(isPresented: $showingQueue) {
                            VStack(alignment: .leading, spacing: 0) {
                                Text("Playing Next")
                                    .font(.headline)
                                    .padding()
                                
                                List {
                                    ForEach(player.queue, id: \.uuid) { queueTrack in
                                        HStack {
                                            if let cover = queueTrack.album?.coverArt, let img = NSImage(data: cover) {
                                                Image(nsImage: img)
                                                    .resizable()
                                                    .frame(width: 32, height: 32)
                                                    .cornerRadius(4)
                                            }
                                            
                                            VStack(alignment: .leading) {
                                                Text(queueTrack.title)
                                                    .font(.system(size: 12, weight: .medium))
                                                Text(queueTrack.album?.artist?.name ?? "")
                                                    .font(.system(size: 10))
                                                    .foregroundColor(.secondary)
                                            }
                                            
                                            Spacer()
                                            
                                            if queueTrack.uuid == track.uuid {
                                                Image(systemName: "waveform")
                                                    .foregroundColor(.accentColor)
                                            }
                                        }
                                        .padding(.vertical, 2)
                                    }
                                }
                                .listStyle(.plain)
                            }
                            .frame(width: 300, height: 400)
                        }
                    }
                    .padding(.trailing, 20)
                }
                .frame(height: 70)
            }
            .background(VisualEffectView(material: .contentBackground, blendingMode: .withinWindow))
            .overlay(Divider(), alignment: .top)
        }
    }
}
