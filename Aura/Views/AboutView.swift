import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) var dismiss
    @State private var animateIcon = false
    
    var body: some View {
        ZStack {
            // Background Vibrancy
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Animated App Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(LinearGradient(colors: [.accentColor, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 100, height: 100)
                        .shadow(color: .accentColor.opacity(0.5), radius: 20, y: 10)
                    
                    Image(systemName: "waveform")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(.white)
                        .symbolEffect(.variableColor.iterative, isActive: animateIcon)
                }
                .scaleEffect(animateIcon ? 1.05 : 1.0)
                .onAppear {
                    withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                        animateIcon = true
                    }
                }
                
                VStack(spacing: 4) {
                    Text("Aura")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                    Text("Version 1.0.0 (Genesis)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                    .frame(width: 200)
                
                VStack(spacing: 8) {
                    Text("Created with ❤️ by")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("ELDAROOS")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .tracking(2)
                }
                
                Text("The Native Music Engine for macOS.\nBuilt using SwiftUI & SwiftData.")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                Spacer()
                
                Button("Close") { dismiss() }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
            .padding(40)
        }
        .frame(width: 350, height: 480)
    }
}
