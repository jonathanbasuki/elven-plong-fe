import SwiftUI

/// Reusable metric card displaying a title (e.g. "Active Staff", "Total Crowd", "Status")
/// and a prominent value or count.
/// Conforms to Apple HIG: clean typography, dynamic colors, and flexible layout.
public struct StatusMetricCard: View {
    public let title: String
    public let value: String
    public var valueColor: Color
    public var showsCardBackground: Bool
    
    public init(
        title: String,
        value: String,
        valueColor: Color = Color(uiColor: .label),
        showsCardBackground: Bool = true
    ) {
        self.title = title
        self.value = value
        self.valueColor = valueColor
        self.showsCardBackground = showsCardBackground
    }
    
    public var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color(uiColor: .secondaryLabel))
                .lineLimit(1)
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .frame(height: showsCardBackground ? 72 : nil)
        .modifier(CardBackgroundModifier(showsCardBackground: showsCardBackground))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

/// Convenience container displaying a side-by-side [Status | Crowd Count] pair
/// as used in Zone Detail Modals and Task Detail views.
public struct StatusMetricsRow: View {
    public let status: String
    public var statusColor: Color
    public let crowdCount: Int
    public var showsCardBackground: Bool
    
    public init(
        status: String = "Overflow",
        statusColor: Color = Color(red: 0.85, green: 0.20, blue: 0.20),
        crowdCount: Int,
        showsCardBackground: Bool = false
    ) {
        self.status = status
        self.statusColor = statusColor
        self.crowdCount = crowdCount
        self.showsCardBackground = showsCardBackground
    }
    
    public var body: some View {
        HStack(spacing: 12) {
            StatusMetricCard(
                title: "Status",
                value: status,
                valueColor: statusColor,
                showsCardBackground: showsCardBackground
            )
            
            StatusMetricCard(
                title: "Crowd Count",
                value: "\(crowdCount)",
                valueColor: Color(uiColor: .label),
                showsCardBackground: showsCardBackground
            )
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Internal Styling Modifier
private struct CardBackgroundModifier: ViewModifier {
    let showsCardBackground: Bool
    
    func body(content: Content) -> some View {
        if showsCardBackground {
            content
                .background(Color(uiColor: .systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 19.5, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 19.5, style: .continuous)
                        .stroke(Color.primary.opacity(0.18), lineWidth: 1)
                )
        } else {
            content
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        // Overview style (with background cards)
        HStack(spacing: 12) {
            StatusMetricCard(title: "Active Staff", value: "18")
            StatusMetricCard(title: "Total Crowd", value: "80")
        }
        
        // Modal / Detail style (minimal row)
        StatusMetricsRow(
            status: "Overflow",
            statusColor: Color(red: 0.85, green: 0.20, blue: 0.20),
            crowdCount: 50
        )
    }
    .padding(20)
}

