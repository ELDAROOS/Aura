import SwiftUI
import SwiftData

struct NowPlayingView: View {
    @Bindable var audioPlayer = AudioPlayerService.shared
    @State private var animateBackground = false
    
    var body: some View {
        if let track = audioPlayer.currentTrack {
            ZStack {
                // MARK: - 1. Animated Mesh Background
                ZStack {
                    Color.black
                    
                    if let artData = track.album?.coverArt, let nsImage = NSImage(data: artData) {
                        GeometryReader { geo in
                            ZStack {
                                Image(nsImage: nsImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: geo.size.width * 1.5)
                                    .blur(radius: 120)
                                    .offset(x: animateBackground ? 100 : -100, y: animateBackground ? -100 : 100)
                                    .scaleEffect(animateBackground ? 1.4 : 1.0)
                                    .opacity(0.7)
                                
                                Image(nsImage: nsImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: geo.size.width * 1.5)
                                    .blur(radius: 140)
                                    .rotationEffect(.degrees(animateBackground ? 360 : 0))
                                    .offset(x: animateBackground ? -150 : 150, y: animateBackground ? 150 : -150)
                                    .opacity(0.5)
                                    .blendMode(.screen)
                            }
                        }
                    }
                    
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .opacity(0.6)
                }
                .ignoresSafeArea()
                .onAppear {
                    withAnimation(.easeInOut(duration: 20).repeatForever(autoreverses: true)) {
                        animateBackground.toggle()
                    }
                }
                
                // MARK: - 2. Top Navigation (Pinned to top)
                VStack {
                    HStack {
                        Button(action: { audioPlayer.isNowPlayingVisible = false }) {
                            Image(systemName: "chevron.down")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        .buttonStyle(.plain)
                        .padding(40)
                        
                        Spacer()
                        
                        Text("Now Playing")
                            .font(.system(size: 13, weight: .bold))
                            .kerning(2)
                            .foregroundColor(.white.opacity(0.3))
                            .textCase(.uppercase)
                            .padding(40)
                        
                        Spacer()
                        
                        // Symmetry
                        Color.clear.frame(width: 100)
                    }
                    Spacer()
                }
                
                // MARK: - 3. Main Content (Perfectly Centered)
                HStack(spacing: 100) {
                    // Artwork
                    ZStack {
                        if let artData = track.album?.coverArt, let nsImage = NSImage(data: artData) {
                            Image(nsImage: nsImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.5), radius: 60, x: 0, y: 40)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                                )
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.white.opacity(0.1))
                                .frame(width: 480, height: 480)
                                .overlay(Image(systemName: "music.note").font(.system(size: 120)).foregroundColor(.white.opacity(0.2)))
                        }
                    }
                    .frame(width: 480, height: 480)
                    
                    // Controls
                    VStack(alignment: .leading, spacing: 45) {
                        VStack(alignment: .leading, spacing: 15) {
                            Text(track.title)
                                .font(.system(size: 56, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(2)
                            
                            Text(track.album?.artist?.name ?? "Unknown Artist")
                                .font(.system(size: 32, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        // Progress
                        VStack(spacing: 15) {
                            Slider(value: Binding(
                                get: { audioPlayer.currentTime },
                                set: { audioPlayer.seek(to: $0) }
                            ), in: 0...(audioPlayer.duration > 0 ? audioPlayer.duration : 1))
                            .accentColor(.white)
                            
                            HStack {
                                Text(audioPlayer.timeString)
                                Spacer()
                                Text(audioPlayer.totalTimeString)
                            }
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.white.opacity(0.5))
                        }
                        
                        // Buttons
                        HStack(spacing: 50) {
                            Button(action: { audioPlayer.previousTrack() }) {
                                Image(systemName: "backward.fill")
                                    .font(.system(size: 32))
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: { audioPlayer.togglePlayPause() }) {
                                Image(systemName: audioPlayer.isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: 72))
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: { audioPlayer.nextTrack() }) {
                                Image(systemName: "forward.fill")
                                    .font(.system(size: 32))
                            }
                            .buttonStyle(.plain)
                            
                            Spacer()
                            
                            HStack(spacing: 12) {
                                Image(systemName: "speaker.fill").font(.caption)
                                Slider(value: $audioPlayer.volume, in: 0...1)
                                    .frame(width: 120)
                                Image(systemName: "speaker.wave.3.fill").font(.caption)
                            }
                            .foregroundColor(.white.opacity(0.4))
                        }
                        .foregroundColor(.white)
                    }
                    .frame(maxWidth: 550)
                }
                .padding(.horizontal, 100)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            .preferredColorScheme(.dark)
        }
    }
}
