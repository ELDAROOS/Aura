import SwiftUI
import UniformTypeIdentifiers
import SwiftData

struct DropZoneView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var isTargeted = false
    @State private var isProcessing = false
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Background with dashed border
            RoundedRectangle(cornerRadius: 16)
                .stroke(isTargeted ? Color.accentColor : Color.secondary.opacity(0.3), 
                        style: StrokeStyle(lineWidth: isTargeted ? 3 : 2, dash: [8]))
                .background(isTargeted ? Color.accentColor.opacity(0.1) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .scaleEffect(isTargeted ? 1.03 : 1.0)
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isTargeted)
                
            VStack(spacing: 12) {
                if isProcessing {
                    ProgressView()
                        .controlSize(.regular)
                        .frame(width: 32, height: 32)
                    Text("Parsing ID3 Tags...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    Image(systemName: "square.and.arrow.down.fill")
                        .font(.system(size: 32))
                        .foregroundColor(isTargeted ? .accentColor : .secondary)
                        .scaleEffect(isTargeted ? 1.2 : 1.0)
                        // In Swift 6 / macOS 14+, we can use symbolEffect
                        .symbolEffect(.bounce, value: isTargeted)
                    
                    Text("Drop Audio Files Here")
                        .font(.headline)
                        .foregroundColor(isTargeted ? .accentColor : .secondary)
                }
            }
        }
        .frame(height: 120)
        .padding(.horizontal)
        .padding(.bottom)
        .onDrop(of: [.audio], isTargeted: $isTargeted) { providers in
            processDrop(providers: providers)
            return true
        }
    }
    
    private func processDrop(providers: [NSItemProvider]) {
        isProcessing = true
        
        Task {
            for provider in providers {
                if provider.hasItemConformingToTypeIdentifier(UTType.audio.identifier) {
                    do {
                        let item = try await provider.loadItem(forTypeIdentifier: UTType.audio.identifier, options: nil)
                        if let url = item as? URL {
                            try await MetadataParser.parseID3Tags(from: url, context: modelContext)
                        }
                    } catch {
                        print("Failed to load drop item: \(error)")
                    }
                }
            }
            
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.3)) {
                    isProcessing = false
                }
            }
        }
    }
}
