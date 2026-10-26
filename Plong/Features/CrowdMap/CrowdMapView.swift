import SwiftUI

public struct CrowdMapView: View {
    @Bindable var viewModel: CrowdMapViewModel
    
    public init(viewModel: CrowdMapViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Venue Overview Header Card
                HStack(spacing: 12) {
                    Image(systemName: "building.2.crop.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Active Monitoring Zone")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        
                        Text(viewModel.venueTitle)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.primary)
                    }
                    
                    Spacer()
                    
                    Text("LIVE")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.12))
                        .clipShape(Capsule())
                }
                .padding(14)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                )
                .padding(.horizontal, 16)
                .padding(.top, 4)
                
                // Key Metrics Summary
                HStack(spacing: 10) {
                    metricCard(
                        title: "Total Crowd",
                        value: "\(viewModel.totalCrowd)",
                        subtitle: "4 zones active",
                        systemIcon: "person.2.fill",
                        tint: .primary
                    )
                    
                    metricCard(
                        title: "High Crowd",
                        value: "\(viewModel.highCrowdZoneCount)",
                        subtitle: viewModel.highCrowdZoneCount > 0 ? "Action required" : "Nominal",
                        systemIcon: "exclamationmark.triangle.fill",
                        tint: viewModel.highCrowdZoneCount > 0 ? .red : .secondary
                    )
                    
                    metricCard(
                        title: "Security",
                        value: "\(viewModel.confirmedAssignmentsCount)",
                        subtitle: "Officers on duty",
                        systemIcon: "shield.checkered",
                        tint: .primary
                    )
                }
                .padding(.horizontal, 16)
                
                // Venue Floor Plan Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("VENUE FLOOR PLAN")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.secondary)
                            
                            Text("Tap a room to inspect density or dispatch security")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    
                    // 2x2 Grid Representation of Venue Floor Plan
                    let zoneA = viewModel.zones.first { $0.id == MockDataConstants.zoneAId } ?? viewModel.zones.first
                    let zoneB = viewModel.zones.first { $0.id == MockDataConstants.zoneBId }
                    let zoneC = viewModel.zones.first { $0.id == MockDataConstants.zoneCId }
                    let zoneD = viewModel.zones.last
                    
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            if let zoneA {
                                zoneRoomView(zone: zoneA)
                            }
                            if let zoneB {
                                zoneRoomView(zone: zoneB)
                            }
                        }
                        
                        HStack(spacing: 12) {
                            if let zoneC {
                                zoneRoomView(zone: zoneC)
                            }
                            if let zoneD {
                                zoneRoomView(zone: zoneD)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                
                // Floor Plan Legend
                HStack(spacing: 16) {
                    legendItem(systemIcon: "checkmark.circle.fill", color: .secondary, label: "Normal (<60%)")
                    legendItem(systemIcon: "exclamationmark.circle.fill", color: .orange, label: "Moderate (60-85%)")
                    legendItem(systemIcon: "exclamationmark.triangle.fill", color: .red, label: "Critical (>85%)")
                }
                .padding(.horizontal, 16)
                .padding(.top, 2)
                
                Spacer(minLength: 32)
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Floor Plan")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.openAlerts()
                } label: {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell.fill")
                            .font(.body)
                            .foregroundStyle(.primary)
                            .frame(width: 44, height: 44)
                        
                        if viewModel.unreadAlertsCount > 0 {
                            Text("\(viewModel.unreadAlertsCount)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color.red)
                                .clipShape(Capsule())
                                .offset(x: 4, y: 4)
                        }
                    }
                }
                .accessibilityLabel("Alerts: \(viewModel.unreadAlertsCount) unread")
            }
        }
    }
    
    // MARK: - Metric Card
    @ViewBuilder
    private func metricCard(
        title: String,
        value: String,
        subtitle: String,
        systemIcon: String,
        tint: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: systemIcon)
                    .font(.caption)
                    .foregroundStyle(tint)
            }
            
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(.primary)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
    
    // MARK: - Zone Room View
    @ViewBuilder
    private func zoneRoomView(zone: VenueZone) -> some View {
        Button {
            viewModel.selectZone(zoneID: zone.id)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                // Room Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(zone.name)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer()
                    
                    severityBadge(severity: zone.crowdSeverity)
                }
                
                Divider()
                    .opacity(0.6)
                
                // Crowd Count
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("\(zone.crowdCount)")
                        .font(.title.weight(.bold))
                        .foregroundStyle(.primary)
                    
                    Text("occupants")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                // Confirmed Security Staff
                let assigned = viewModel.assignedStaff(for: zone)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "shield.checkered")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        
                        Text("Security:")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    
                    if assigned.isEmpty {
                        Text("None (0 assigned)")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    } else {
                        ForEach(assigned) { staff in
                            HStack(spacing: 5) {
                                Circle()
                                    .fill(Color.primary.opacity(0.2))
                                    .frame(width: 6, height: 6)
                                Text(staff.name)
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                }
                
                Spacer(minLength: 6)
                
                // Action link indicator
                HStack {
                    Spacer()
                    HStack(spacing: 4) {
                        Text("Details")
                            .font(.caption2.weight(.semibold))
                        Image(systemName: "chevron.right")
                            .font(.caption2.weight(.semibold))
                    }
                    .foregroundStyle(.secondary)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 180, alignment: .topLeading)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(zoneBorderColor(for: zone.crowdSeverity), lineWidth: zone.crowdSeverity == .high || zone.crowdSeverity == .critical ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func zoneBorderColor(for severity: CrowdSeverity) -> Color {
        switch severity {
        case .low:
            return Color.primary.opacity(0.08)
        case .moderate:
            return Color.orange.opacity(0.4)
        case .high, .critical:
            return Color.red.opacity(0.7)
        }
    }
    
    @ViewBuilder
    private func severityBadge(severity: CrowdSeverity) -> some View {
        HStack(spacing: 4) {
            Image(systemName: severityIcon(for: severity))
                .font(.system(size: 9, weight: .bold))
            Text(severity.label.uppercased())
                .font(.system(size: 9, weight: .bold))
        }
        .foregroundStyle(severityTextColor(for: severity))
        .padding(.horizontal, 7)
        .padding(.vertical, 3.5)
        .background(severityBackgroundColor(for: severity))
        .clipShape(Capsule())
    }
    
    private func severityIcon(for severity: CrowdSeverity) -> String {
        switch severity {
        case .low:
            return "checkmark.circle.fill"
        case .moderate:
            return "exclamationmark.circle.fill"
        case .high, .critical:
            return "exclamationmark.triangle.fill"
        }
    }
    
    private func severityTextColor(for severity: CrowdSeverity) -> Color {
        switch severity {
        case .low:
            return .secondary
        case .moderate:
            return .orange
        case .high, .critical:
            return .red
        }
    }
    
    private func severityBackgroundColor(for severity: CrowdSeverity) -> Color {
        switch severity {
        case .low:
            return Color.primary.opacity(0.06)
        case .moderate:
            return Color.orange.opacity(0.12)
        case .high, .critical:
            return Color.red.opacity(0.14)
        }
    }
    
    @ViewBuilder
    private func legendItem(systemIcon: String, color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: systemIcon)
                .font(.caption2)
                .foregroundStyle(color)
            
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}
