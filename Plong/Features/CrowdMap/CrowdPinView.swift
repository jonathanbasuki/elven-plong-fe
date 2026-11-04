import SwiftUI

/// An interactive, animated crowd detection pin symbol aligned with the overview design.
/// Rendered in vibrant red with pulsating radar rings to signal crowd detection.
public struct CrowdPinView: View {
    public let count: Int
    public let action: () -> Void
    
    @State private var isPulsing: Bool = false
    @State private var isPressed: Bool = false
    
    public init(count: Int = 50, action: @escaping () -> Void) {
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
                // Expanding radar pulse wave 2
                Circle()
                    .stroke(Color.red.opacity(isPulsing ? 0.0 : 0.45), lineWidth: 1.5)
                    .frame(width: isPulsing ? 86 : 38, height: isPulsing ? 86 : 38)
                
                // Expanding radar pulse wave 1
                Circle()
                    .stroke(Color.red.opacity(isPulsing ? 0.0 : 0.7), lineWidth: 2)
                    .frame(width: isPulsing ? 64 : 38, height: isPulsing ? 64 : 38)
                
                // Glowing soft aura behind pin
                Circle()
                    .fill(Color.red.opacity(0.22))
                    .frame(width: 44, height: 44)
                
                // Pin asset from Figma / sample overview rendered in vibrant red
                Image("crowd_pin")
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(Color.red)
                    .frame(width: 40, height: 40)
                    .shadow(color: Color.red.opacity(0.55), radius: 6, x: 0, y: 3)
                
                // Small badge indicator with exclamation or count alert
                Circle()
                    .fill(Color.white)
                    .frame(width: 14, height: 14)
                    .overlay(
                        Circle()
                            .fill(Color.red)
                            .frame(width: 10, height: 10)
                    )
                    .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
                    .offset(x: 13, y: -15)
            }
            .scaleEffect(isPressed ? 0.90 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.7).repeatForever(autoreverses: false)) {
                isPulsing = true
            }
        }
        .accessibilityLabel("Crowd Alert Pin: \(count) occupants detected. Tap for zone details.")
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

