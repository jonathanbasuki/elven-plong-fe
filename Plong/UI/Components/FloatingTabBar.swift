import SwiftUI

public enum MainTab: Hashable, Sendable {
    case overview
    case taskLog
}

/// Reusable Floating Tab Bar matching sample/Manager/overview1.svg and sample/Manager/Task log.svg.
/// Conforms to Apple HIG for custom navigation and touch targets.
public struct FloatingTabBar: View {
    public let activeTab: MainTab
    public let onSelectTab: (MainTab) -> Void
    
    private let activeBlue = Color(red: 0.05, green: 0.49, blue: 0.98) // #0D7CF2
    
    public init(activeTab: MainTab, onSelectTab: @escaping (MainTab) -> Void) {
        self.activeTab = activeTab
        self.onSelectTab = onSelectTab
    }
    
    public var body: some View {
        HStack(spacing: 6) {
            // Overview Tab Button
            Button {
                if activeTab != .overview {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    onSelectTab(.overview)
                }
            } label: {
                ZStack {
                    if activeTab == .overview {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color(uiColor: .systemBackground))
                            .frame(width: 84, height: 48)
                            .shadow(color: Color.black.opacity(0.08), radius: 4, y: 1)
                    } else {
                        Color.clear
                            .frame(width: 84, height: 48)
                    }
                    
                    VStack(spacing: 4) {
                        // Diamond / Rhombus Icon
                        Rectangle()
                            .fill(activeTab == .overview ? activeBlue : Color.black.opacity(0.8))
                            .frame(width: 12, height: 12)
                            .rotationEffect(.degrees(45))
                        
                        Text("Overview")
                            .font(.system(size: 10, weight: activeTab == .overview ? .bold : .medium))
                            .foregroundStyle(activeTab == .overview ? activeBlue : Color.black.opacity(0.8))
                    }
                }
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
            .accessibilityLabel("Overview Tab")
            .accessibilityAddTraits(activeTab == .overview ? [.isSelected] : [])
            
            // Task Log Tab Button
            Button {
                if activeTab != .taskLog {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    onSelectTab(.taskLog)
                }
            } label: {
                ZStack {
                    if activeTab == .taskLog {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color(uiColor: .systemBackground))
                            .frame(width: 84, height: 48)
                            .shadow(color: Color.black.opacity(0.08), radius: 4, y: 1)
                    } else {
                        Color.clear
                            .frame(width: 84, height: 48)
                    }
                    
                    VStack(spacing: 4) {
                        // Circle Icon
                        Circle()
                            .fill(activeTab == .taskLog ? activeBlue : Color.black.opacity(0.8))
                            .frame(width: 12, height: 12)
                        
                        Text("Task Log")
                            .font(.system(size: 10, weight: activeTab == .taskLog ? .bold : .medium))
                            .foregroundStyle(activeTab == .taskLog ? activeBlue : Color.black.opacity(0.8))
                    }
                }
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
            .accessibilityLabel("Task Log Tab")
            .accessibilityAddTraits(activeTab == .taskLog ? [.isSelected] : [])
        }
        .padding(.horizontal, 6)
        .frame(width: 194, height: 60)
        .background(
            Capsule()
                .fill(Color(uiColor: .systemGray2).opacity(0.85))
                .background(.ultraThinMaterial, in: Capsule())
        )
        .overlay(
            Capsule()
                .stroke(Color.primary.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 4)
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.2).ignoresSafeArea()
        VStack(spacing: 20) {
            FloatingTabBar(activeTab: .overview, onSelectTab: { _ in })
            FloatingTabBar(activeTab: .taskLog, onSelectTab: { _ in })
        }
    }
}
