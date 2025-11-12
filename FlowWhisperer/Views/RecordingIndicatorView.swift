import SwiftUI

struct RecordingIndicatorView: View {
    @EnvironmentObject var appSettings: AppSettings
    @State private var pulseScale: CGFloat = 1.0
    @State private var opacity: Double = 0.7
    
    var body: some View {
        Group {
            Circle()
                .fill(indicatorGradient)
                .frame(width: 30, height: 30)
                .scaleEffect(pulseScale)
                .opacity(opacity)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: pulseScale)
                .animation(.easeInOut(duration: 0.3), value: opacity)
                .onAppear {
                    print("🔵 DEBUG: RecordingIndicatorView appeared")
                    print("🔵 DEBUG: Initial state: \(appSettings.indicatorState)")
                    startAnimations()
                }
                .onChange(of: appSettings.indicatorState) { newState in
                    print("🔵 DEBUG: Indicator state changed to: \(newState)")
                    updateAnimations(for: newState)
                }
        }
        .frame(width: 40, height: 40)
    }
    
    private var indicatorGradient: LinearGradient {
        switch appSettings.indicatorState {
        case .hidden:
            return LinearGradient(colors: [.clear], startPoint: .top, endPoint: .bottom)
        case .idle:
            return LinearGradient(
                colors: [Color.gray.opacity(0.6), Color.black.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
        case .recording:
            return LinearGradient(
                colors: [Color.blue.opacity(0.8), Color.black],
                startPoint: .top,
                endPoint: .bottom
            )
        case .processing:
            return LinearGradient(
                colors: [Color.blue.opacity(0.9), Color.purple.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )
        case .success:
            return LinearGradient(
                colors: [Color.green.opacity(0.8), Color.black],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    
    private func startAnimations() {
        updateAnimations(for: appSettings.indicatorState)
    }
    
    private func updateAnimations(for state: IndicatorState) {
        print("🔵 DEBUG: Updating animations for state: \(state)")
        
        switch state {
        case .hidden:
            print("🔵 DEBUG: Setting hidden state - opacity: 0.0")
            opacity = 0.0
            pulseScale = 1.0
            
        case .idle:
            print("🔵 DEBUG: Setting idle state - opacity: 0.7")
            opacity = 0.7
            pulseScale = 1.0
            
        case .recording:
            print("🔵 DEBUG: Setting recording state - opacity: 0.9, pulsing")
            opacity = 0.9
            pulseScale = 1.2
            
        case .processing:
            print("🔵 DEBUG: Setting processing state - opacity: 1.0")
            opacity = 1.0
            pulseScale = 1.1
            
        case .success:
            print("🔵 DEBUG: Setting success state - opacity: 1.0, will auto-hide in 2s")
            opacity = 1.0
            pulseScale = 1.0
            
            // Auto-hide after success
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                print("🔵 DEBUG: Auto-hiding success state back to idle")
                appSettings.indicatorState = .idle
            }
        }
    }
}