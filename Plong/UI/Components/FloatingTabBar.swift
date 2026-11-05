import SwiftUI

public enum MainTab: Hashable, Sendable {
    case overview
    case taskLog
}

/// A polished, Apple-inspired translucent floating tab bar with Liquid Glass styling
/// and buttery-smooth matched-geometry sliding transitions.
public struct FloatingTabBar: View {
    public let activeTab: MainTab
    public let onSelectTab: (MainTab) -> Void
    
    @Namespace private var tabIndicatorNamespace
    private let activeBlue = Color(red: 0.05, green: 0.49, blue: 0.98) // #0D7CF2
    
    public init(activeTab: MainTab, onSelectTab: @escaping (MainTab) -> Void) {
        self.activeTab = activeTab
        self.onSelectTab = onSelectTab
    }
    
    public var body: some View {
        HStack(spacing: 4) {
            // Overview Tab Button
            tabButton(
                tab: .overview,
                title: "Overview",
                accessibilityText: "Overview Tab"
            ) {
                // Diamond / Rhombus Icon matching Figma sample
                Rectangle()
                    .fill(activeTab == .overview ? activeBlue : Color(uiColor: .secondaryLabel))
                    .frame(width: 12, height: 12)
                    .rotationEffect(.degrees(45))
            }
            
            // Task Log Tab Button
            tabButton(
                tab: .taskLog,
                title: "Task Log",
                accessibilityText: "Task Log Tab"
            ) {
                // Circle Icon matching Figma sample
                Circle()
                    .fill(activeTab == .taskLog ? activeBlue : Color(uiColor: .secondaryLabel))
                    .frame(width: 12, height: 12)
            }
        }
        .padding(.horizontal, 6)
        .frame(width: 200, height: 58)
        // Polished Apple Translucent Glass Background
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .fill(Color(uiColor: .systemBackground).opacity(0.35))
                )
        )
        // Specular highlight gradient rim inspired by Apple Liquid Glass
        .overlay(
            Capsule()
                .stroke(
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(0.70), location: 0.0),
                            .init(color: Color.white.opacity(0.25), location: 0.45),
                            .init(color: Color.black.opacity(0.08), location: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.9
                )
        )
        // Apple-style layered elevation shadows
        .shadow(color: Color.black.opacity(0.12), radius: 18, x: 0, y: 7)
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 1)
    }
    
    // MARK: - Tab Button with Matched Geometry Sliding Thumb
    @ViewBuilder
    private func tabButton<Icon: View>(
        tab: MainTab,
        title: String,
        accessibilityText: String,
        @ViewBuilder icon: () -> Icon
    ) -> some View {
        Button {
            if activeTab != tab {
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    onSelectTab(tab)
                }
            }
        } label: {
            ZStack {
                // Smooth Sliding Glass Thumb
                if activeTab == tab {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color(uiColor: .systemBackground).opacity(0.94))
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(Color.white.opacity(0.6), lineWidth: 0.8)
                        )
                        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 2)
                        .matchedGeometryEffect(id: "activeTabIndicator", in: tabIndicatorNamespace)
                }
                
                VStack(spacing: 3) {
                    icon()
                    
                    Text(title)
                        .font(.system(size: 11, weight: activeTab == tab ? .bold : .medium))
                        .foregroundStyle(activeTab == tab ? activeBlue : Color(uiColor: .secondaryLabel))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
            }
            .frame(height: 46)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(activeTab == tab ? [.isSelected] : [])
    }
}

#Preview {
    ZStack {
        LinearGradient(colors: [Color.blue.opacity(0.15), Color.purple.opacity(0.15)], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
        
        VStack(spacing: 24) {
            FloatingTabBar(activeTab: .overview, onSelectTab: { _ in })
            FloatingTabBar(activeTab: .taskLog, onSelectTab: { _ in })
        }
    }
}
