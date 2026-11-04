import SwiftUI

/// Reusable Primary CTA Pill Button matching the Figma/SVG design.
/// Standard 50pt height, brand blue fill (#006ADA), semibold white text, and light haptic feedback.
public struct PrimaryPillButton: View {
    public let title: String
    public var icon: String? = nil
    public var width: CGFloat? = nil
    public var isEnabled: Bool = true
    public var isLoading: Bool = false
    public let action: () -> Void
    
    public init(
        title: String,
        icon: String? = nil,
        width: CGFloat? = nil,
        isEnabled: Bool = true,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.width = width
        self.isEnabled = isEnabled
        self.isLoading = isLoading
        self.action = action
    }
    
    public var body: some View {
        Button {
            guard !isLoading else { return }
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            action()
        } label: {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                }
            }
            .foregroundStyle(Color.white)
            .frame(maxWidth: width == nil ? .infinity : nil)
            .frame(width: width)
            .frame(height: 50)
            .background(isEnabled && !isLoading ? PlongTheme.Colors.brandBlue : PlongTheme.Colors.brandBlue.opacity(0.4))
            .clipShape(Capsule())
            .shadow(
                color: isEnabled && !isLoading ? PlongTheme.Colors.brandBlue.opacity(0.35) : Color.clear,
                radius: 6,
                x: 0,
                y: 3
            )
        }
        .disabled(!isEnabled || isLoading)
    }
}

#Preview {
    VStack(spacing: 16) {
        PrimaryPillButton(title: "Delegate", action: {})
        PrimaryPillButton(title: "Done", width: 113, action: {})
        PrimaryPillButton(title: "Disabled", isEnabled: false, action: {})
    }
    .padding()
}
