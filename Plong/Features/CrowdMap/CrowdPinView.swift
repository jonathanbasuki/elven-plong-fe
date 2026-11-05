import SwiftUI

/// A clean, stationary crowd sensor marker aligned with Apple HIG and the overview design.
/// Stays still without distracting animations, providing clear and stable visual status.
public struct CrowdPinView: View {
    public let count: Int
    public let action: () -> Void
    
    @State private var isPressed: Bool = false
    
    public init(count: Int = 50, action: @escaping () -> Void = {}) {
        self.count = count
        self.action = action
    }
    
    public var body: some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            action()
        } label: {
            ZStack {
                // Stationary camera/sensor circle matching Figma overview
                Circle()
                    .fill(Color.black)
                    .frame(width: 30, height: 30)
                    .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 2)
                
                // Sensor direction / aperture cutout arc
                Circle()
                    .stroke(Color(red: 0.35, green: 0.65, blue: 1.0), lineWidth: 2.5)
                    .frame(width: 30, height: 30)
                
                // Clean CCTV icon
                Image(systemName: "video.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .scaleEffect(isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Zone Sensor: \(count) occupants detected. Tap for zone details.")
    }
}

#Preview {
    ZStack {
        Color(uiColor: .systemGray6)
            .ignoresSafeArea()
        
        CrowdPinView(count: 50) {
            print("Pin tapped")
        }
    }
}
