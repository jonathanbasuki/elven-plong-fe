import SwiftUI

public struct ZoneDetailView: View {
    @Bindable var viewModel: ZoneDetailViewModel
    
    public init(viewModel: ZoneDetailViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if let zone = viewModel.zone {
                    // Zone Overview Card
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(zone.name)
                                    .font(.title2.weight(.bold))
                                    .foregroundStyle(.primary)
                                
                                Text("Zone \(zone.id.uppercased())")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            statusBadge(status: zone.status)
                        }
                        
                        Divider()
                            .opacity(0.5)
                        
                        // Live Headcount & Density
                        HStack(alignment: .lastTextBaseline) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(zone.currentCount)")
                                    .font(.system(size: 38, weight: .bold, design: .rounded))
                                    .foregroundStyle(headcountColor(for: zone.status))
                                
                                Text("Live Occupancy")
                                    .font(.footnote.weight(.medium))
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Capacity Thresholds")
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(.secondary)
                                
                                Text("\(zone.warningThreshold) warn · \(zone.crowdedThreshold) limit")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(.primary)
                            }
                        }
                        
                        // Occupancy Progress Indicator
                        ProgressView(
                            value: min(Double(zone.currentCount), Double(zone.crowdedThreshold)),
                            total: Double(max(zone.crowdedThreshold, 1))
                        )
                        .tint(headcountColor(for: zone.status))
                    }
                    .padding(16)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    
                    // Active Broadcast or Broadcast CTA
                    if let broadcast = viewModel.activeBroadcast, broadcast.status == .open || (broadcast.status == .closed && broadcast.acceptedCount > 0) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(broadcast.status == .open ? Color.blue : Color.green)
                                        .frame(width: 8, height: 8)
                                    
                                    Text(broadcast.status == .open ? "Broadcast in Progress" : "Delegation Active")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(broadcast.status == .open ? Color.blue : Color.green)
                                }
                                
                                Spacer()
                                
                                Text("\(broadcast.acceptedCount) of \(broadcast.staffNeeded) joined")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.secondary)
                            }
                            
                            Button {
                                viewModel.navigateToLiveBroadcast()
                            } label: {
                                HStack(spacing: 6) {
                                    Text("View Live Session")
                                        .font(.subheadline.weight(.semibold))
                                    Image(systemName: "chevron.right")
                                        .font(.caption2.weight(.bold))
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 42)
                                .foregroundStyle(Color(uiColor: .systemBackground))
                                .background(Color.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                        }
                        .padding(16)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .padding(.horizontal, 16)
                    } else {
                        Button {
                            viewModel.navigateToCreateBroadcast()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "paperplane.fill")
                                    .font(.subheadline.weight(.semibold))
                                Text("Broadcast to Staff")
                                    .font(.body.weight(.semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .foregroundStyle(Color(uiColor: .systemBackground))
                            .background(Color.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .padding(.horizontal, 16)
                    }
                    
                    // Assigned Personnel Section
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Assigned Officers")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.secondary)
                            
                            Spacer()
                            
                            Text("\(viewModel.assignedStaff.count) active")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 18)
                        
                        if viewModel.assignedStaff.isEmpty {
                            Text("No officers currently assigned to this zone.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(16)
                                .background(Color(uiColor: .secondarySystemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .padding(.horizontal, 16)
                        } else {
                            VStack(spacing: 8) {
                                ForEach(viewModel.assignedStaff) { staff in
                                    HStack(spacing: 12) {
                                        Image(systemName: "person.crop.circle.fill")
                                            .font(.system(size: 32))
                                            .foregroundStyle(.secondary)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(staff.name)
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(.primary)
                                            Text(staff.status == .delegating ? "On Duty" : "Standby")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Text(staff.status == .delegating ? "Active" : "Idle")
                                            .font(.caption2.weight(.medium))
                                            .foregroundStyle(staff.status == .delegating ? Color.blue : Color.secondary)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(staff.status == .delegating ? Color.blue.opacity(0.12) : Color.primary.opacity(0.06))
                                            .clipShape(Capsule())
                                    }
                                    .padding(12)
                                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    
                } else {
                    ContentUnavailableView(
                        "Zone Not Found",
                        systemImage: "mappin.slash",
                        description: Text("The requested zone could not be found.")
                    )
                    .padding(24)
                }
                
                Spacer(minLength: 32)
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(viewModel.zone?.name ?? "Zone")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Helpers
    
    @ViewBuilder
    private func statusBadge(status: ZoneStatus) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor(for: status))
                .frame(width: 6, height: 6)
            Text(status.label.capitalized)
                .font(.caption.weight(.medium))
        }
        .foregroundStyle(statusColor(for: status))
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(statusColor(for: status).opacity(0.12))
        .clipShape(Capsule())
    }
    
    private func headcountColor(for status: ZoneStatus) -> Color {
        switch status {
        case .safe: return .primary
        case .warning: return .orange
        case .crowded: return .red
        }
    }
    
    private func statusColor(for status: ZoneStatus) -> Color {
        switch status {
        case .safe: return .green
        case .warning: return .orange
        case .crowded: return .red
        }
    }
}
