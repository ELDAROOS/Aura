import SwiftUI

struct EqualizerView: View {
    @Bindable var audioPlayer = AudioPlayerService.shared
    @Environment(\.dismiss) var dismiss
    
    let frequencies = ["32", "64", "125", "250", "500", "1K", "2K", "4K", "8K", "16K"]
    let presets = ["Flat", "Rock", "Jazz", "Bass Boost"]
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Equalizer")
                    .font(.title2).bold()
                Spacer()
                Button("Done") { dismiss() }
                    .buttonStyle(.borderedProminent)
            }
            .padding(.bottom, 10)
            
            // Presets
            HStack {
                ForEach(presets, id: \.self) { preset in
                    Button(action: { audioPlayer.applyPreset(preset) }) {
                        Text(preset)
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(audioPlayer.currentPreset == preset ? Color.accentColor : Color.secondary.opacity(0.2))
                            .cornerRadius(8)
                            .foregroundColor(audioPlayer.currentPreset == preset ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Band Sliders
            HStack(alignment: .bottom, spacing: 12) {
                ForEach(0..<10, id: \.self) { i in
                    VStack {
                        Text("\(Int(audioPlayer.eqBands[i]))dB")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary)
                        
                        Slider(value: $audioPlayer.eqBands[i], in: -12...12, step: 1)
                            .controlSize(.small)
                            .rotationEffect(.degrees(-90))
                            .frame(width: 30, height: 150)
                        
                        Text(frequencies[i])
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.accentColor)
                    }
                }
            }
            .frame(height: 220)
            .padding(.vertical)
            
            Text("Adjust individual bands to fine-tune your sound.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(25)
        .frame(width: 500)
        .background(.ultraThinMaterial)
    }
}
