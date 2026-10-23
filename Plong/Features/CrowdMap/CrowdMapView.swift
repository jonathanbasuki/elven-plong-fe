import SwiftUI

public struct CrowdMapView: View {
    @Bindable var viewModel: CrowdMapViewModel
    
    public init(viewModel: CrowdMapViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header Bar
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("CrowdFlow")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.gray)
                        
                        Text(viewModel.venueTitle)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.black)
                    }
                    
                    Spacer()
                    
                    Button {
                        viewModel.openAlerts()
                    } label: {
                        HStack(spacing: 6) {
                            Text("Alerts")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.black)
                            
                            if viewModel.unreadAlertsCount > 0 {
                                Text("\(viewModel.unreadAlertsCount)")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.black)
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(white: 0.95))
                        .border(Color.black, width: 1)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                Divider()
                    .padding(.horizontal, 16)
                
                // Key Metrics Summary (Low-Fidelity Cards)
                HStack(spacing: 12) {
                    metricCard(
                        title: "Total Crowd",
                        value: "\(viewModel.totalCrowd)",
                        subtitle: "Across 4 zones"
                    )
                    
                    metricCard(
                        title: "High Crowd",
                        value: "\(viewModel.highCrowdZoneCount)",
                        subtitle: "Action required"
                    )
                    
                    metricCard(
                        title: "Security",
                        value: "\(viewModel.confirmedAssignmentsCount)",
                        subtitle: "Confirmed"
                    )
                }
                .padding(.horizontal, 16)
                
                // Venue Floor Plan Section
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("VENUE FLOOR PLAN")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.gray)
                        
                        Spacer()
                        
                        Text("Select a zone to manage")
                            .font(.caption2)
                            .foregroundStyle(.gray)
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
                    legendItem(color: Color(white: 0.92), label: "Low (Normal)")
                    legendItem(color: Color(white: 0.85), label: "Moderate")
                    legendItem(color: Color.black, label: "High / Critical", textColor: .black)
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                
                Spacer(minLength: 24)
            }
        }
        .background(Color.white)
        .navigationBarHidden(true)
    }
    
    @ViewBuilder
    private func metricCard(title: String, value: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(.gray)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.black)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(white: 0.96))
        .border(Color.gray.opacity(0.3), width: 1)
    }
    
    @ViewBuilder
    private func zoneRoomView(zone: VenueZone) -> some View {
        Button {
            viewModel.selectZone(zoneID: zone.id)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                // Room Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(zone.name)
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(.black)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer()
                    
                    severityBadge(severity: zone.crowdSeverity)
                }
                
                Divider()
                
                // Crowd Count
                HStack(alignment: .firstTextBaseline) {
                    Text("\(zone.crowdCount)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.black)
                    
                    Text("people")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                
                // Confirmed Security Staff
                let assigned = viewModel.assignedStaff(for: zone)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Security Deployed:")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.gray)
                    
                    if assigned.isEmpty {
                        Text("None (0 assigned)")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    } else {
                        ForEach(assigned) { staff in
                            HStack(spacing: 4) {
                                Rectangle()
                                    .fill(Color.black)
                                    .frame(width: 4, height: 4)
                                Text(staff.name)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.black)
                            }
                        }
                    }
                }
                
                Spacer(minLength: 4)
                
                // Action link
                HStack {
                    Spacer()
                    Text("View Zone →")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.black)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 180, alignment: .topLeading)
            .background(zoneBackgroundColor(for: zone.crowdSeverity))
            .border(zoneBorderColor(for: zone.crowdSeverity), width: zone.crowdSeverity == .high ? 2 : 1)
        }
        .buttonStyle(.plain)
    }
    
    private func zoneBackgroundColor(for severity: CrowdSeverity) -> Color {
        switch severity {
        case .low:
            return Color(white: 0.98)
        case .moderate:
            return Color(white: 0.94)
        case .high, .critical:
            return Color(white: 0.90)
        }
    }
    
    private func zoneBorderColor(for severity: CrowdSeverity) -> Color {
        switch severity {
        case .low, .moderate:
            return Color.gray.opacity(0.4)
        case .high, .critical:
            return Color.black
        }
    }
    
    @ViewBuilder
    private func severityBadge(severity: CrowdSeverity) -> some View {
        Text(severity.label.uppercased())
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(severity == .high || severity == .critical ? Color.white : Color.black)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(severity == .high || severity == .critical ? Color.black : Color(white: 0.85))
    }
    
    @ViewBuilder
    private func legendItem(color: Color, label: String, textColor: Color = .gray) -> some View {
        HStack(spacing: 6) {
            Rectangle()
                .fill(color)
                .frame(width: 12, height: 12)
                .border(Color.gray.opacity(0.4), width: 1)
            
            Text(label)
                .font(.caption2)
                .foregroundStyle(textColor)
        }
    }
}
