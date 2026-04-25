import SwiftUI
import SwiftData

struct LyricsView: View {
    @Bindable var track: Track
    @Environment(\.dismiss) private var dismiss
    @State private var isTranscribing = false
    @State private var errorMessage: String?
    
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
                    VStack(alignment: .leading, spacing: 12) {
                        if let lyrics = track.lyrics {
                            if !lyrics.isEmpty {
                                Text(lyrics)
                                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)
                                    .lineSpacing(10)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .shadow(color: .black.opacity(0.1), radius: 2)
                                    .padding(.bottom, 80)
                            } else {
                                emptyStateView
                            }
                        } else {
                            emptyStateView
                        }
                    }
                    .padding(.horizontal, 60)
                    .padding(.top, 30)
                }
                .overlay(
                    LinearGradient(gradient: Gradient(colors: [.clear, .black.opacity(0.3)]), startPoint: .center, endPoint: .bottom)
                        .allowsHitTesting(false)
                )
            }
        }
        .frame(minWidth: 700, minHeight: 800)
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 100)
            Image(systemName: isTranscribing ? "waveform.and.mic" : "music.note.list")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.2))
                .symbolEffect(.variableColor.iterative, isActive: isTranscribing)
            
            Text(isTranscribing ? "Aura AI is listening..." : "Lyrics not found")
                .font(.title2)
                .bold()
                .foregroundColor(.white.opacity(0.4))
            
            if !isTranscribing {
                Button(action: { transcribeTrack() }) {
                    Label("Transcribe with AI", systemImage: "sparkles")
                        .font(.headline)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(Color.white.opacity(0.2)))
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)
            }
            
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private func transcribeTrack() {
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        guard let fileName = track.localFileName else {
            errorMessage = "Local file not found."
            return
        }
        let url = documentsDir.appendingPathComponent(fileName)
        
        isTranscribing = true
        errorMessage = nil
        
        Task {
            do {
                let transcription = try await AITranscriptionService.transcribe(url: url)
                await MainActor.run {
                    track.lyrics = transcription
                    try? track.modelContext?.save()
                    isTranscribing = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isTranscribing = false
                }
            }
        }
    }
}
