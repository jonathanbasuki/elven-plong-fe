import SwiftUI

/// Reusable Secondary Pill Button matching the Figma/SVG design.
/// Standard 50pt height, translucent gray fill (#767680 @ 12%), and customizable active/disabled state.
public struct SecondaryPillButton: View {
    public let title: String
    public var width: CGFloat? = nil
    public var isEnabled: Bool = true
    public let action: () -> Void
    
    public init(
        title: String,
        width: CGFloat? = nil,
        isEnabled: Bool = true,
        action: @escaping () -> Void = {}
    ) {
        self.title = title
        self.width = width
        self.isEnabled = isEnabled
        self.action = action
    }
    
    public var body: some View {
        Button {
            guard isEnabled else { return }
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            action()
        } label: {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(isEnabled ? Color(uiColor: .label) : PlongTheme.Colors.disabledText)
                .frame(maxWidth: width == nil ? .infinity : nil)
                .frame(width: width)
                .frame(height: 50)
                .background(PlongTheme.Colors.secondaryButtonBackground)
                .clipShape(Capsule())
        }
        .disabled(!isEnabled)
    }
}

#Preview {
    HStack(spacing: 12) {
        SecondaryPillButton(title: "Delegate", isEnabled: true, action: {})
        SecondaryPillButton(title: "Done", width: 113, isEnabled: false, action: {})
    }
    .padding()
}
