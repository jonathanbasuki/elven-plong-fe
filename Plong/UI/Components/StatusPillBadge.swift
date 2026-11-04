import SwiftUI

public enum StatusBadgeStyle {
    case ongoing
    case done
    case role(String)
    case overflowed
    case custom(title: String, textColor: Color, backgroundColor: Color)
}

/// Reusable status pill badge component used for task statuses, officer roles, and zone conditions.
public struct StatusPillBadge: View {
    public let style: StatusBadgeStyle
    public var width: CGFloat? = nil
    public var height: CGFloat = 24
    
    public init(style: StatusBadgeStyle, width: CGFloat? = nil, height: CGFloat = 24) {
        self.style = style
        self.width = width
        self.height = height
    }
    
    public var body: some View {
        Text(title)
            .font(.system(size: fontSize, weight: .semibold))
            .foregroundStyle(textColor)
            .frame(width: width)
            .frame(height: height)
            .padding(.horizontal, width == nil ? 10 : 0)
            .background(backgroundColor)
            .clipShape(Capsule())
    }
    
    private var title: String {
        switch style {
        case .ongoing: return "Ongoing"
        case .done: return "Done"
        case .role(let text): return text
        case .overflowed: return "Overflowed"
        case .custom(let title, _, _): return title
        }
    }
    
    private var textColor: Color {
        switch style {
        case .ongoing: return PlongTheme.Colors.ongoingBlue
        case .done: return PlongTheme.Colors.doneGreen
        case .role: return Color.black
        case .overflowed: return PlongTheme.Colors.overflowRed
        case .custom(_, let textColor, _): return textColor
        }
    }
    
    private var backgroundColor: Color {
        switch style {
        case .ongoing: return PlongTheme.Colors.ongoingBackground
        case .done: return PlongTheme.Colors.doneBackground
        case .role: return Color.white
        case .overflowed: return PlongTheme.Colors.overflowRed.opacity(0.12)
        case .custom(_, _, let bg): return bg
        }
    }
    
    private var fontSize: CGFloat {
        switch style {
        case .role: return 13
        default: return 12
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        StatusPillBadge(style: .ongoing, width: 74)
        StatusPillBadge(style: .done, width: 74)
        StatusPillBadge(style: .role("security"), width: 85, height: 28)
        StatusPillBadge(style: .overflowed)
    }
    .padding()
}
