import SwiftUI

public struct BroadcastView: View {
    @Bindable var viewModel: BroadcastViewModel
    @State private var isSimulationExpanded: Bool = false
    
    public init(viewModel: BroadcastViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // Zone & Broadcast Overview Card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(viewModel.zone?.name ?? "Zone \(viewModel.zoneID)")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(.primary)
                            
                            Text("Broadcast Delegation")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        if let broadcast = viewModel.broadcast {
                            statusPill(status: broadcast.status)
                        }
                    }
                }
                .padding(16)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal, 16)
                .padding(.top, 4)
                
                // Error Alert Banner if any
                if let errorMessage = viewModel.errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(.red)
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                        Spacer()
                    }
                    .padding(12)
                    .background(Color.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .padding(.horizontal, 16)
                }
                
                if let broadcast = viewModel.broadcast {
                    if broadcast.status == .open || (broadcast.status == .closed && broadcast.acceptedCount == 0) {
                        // Manager Page 3: Looking for staff / Countdown
                        page3CountdownCard(broadcast: broadcast)
                            .padding(.horizontal, 16)
                    } else {
                        // Manager Page 4: Accepted staff delegation list & Finish
                        page4DelegationCard(broadcast: broadcast)
                            .padding(.horizontal, 16)
                    }
                } else {
                    ContentUnavailableView(
                        "No Active Broadcast",
                        systemImage: "antenna.radiowaves.left.and.right.slash",
                        description: Text("No broadcast session found for this zone.")
                    )
                    .padding(24)
                }
                
                // Unobtrusive Simulation Drawer
                simulationDrawer
                    .padding(.horizontal, 16)
                
                Spacer(minLength: 32)
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Delegation")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if viewModel.broadcast?.status == .open {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel", role: .destructive) {
                        viewModel.cancelBroadcast()
                    }
                    .font(.subheadline)
                }
            }
        }
    }
    
    // MARK: - Manager Page 3: Looking for Staff Card
    @ViewBuilder
    private func page3CountdownCard(broadcast: BroadcastSession) -> some View {
        VStack(spacing: 16) {
            if broadcast.status == .open {
                // Sleek Circular Countdown & Slots
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .stroke(Color.primary.opacity(0.08), lineWidth: 6)
                            .frame(width: 88, height: 88)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(viewModel.remainingSeconds) / 20.0)
                            .stroke(
                                viewModel.remainingSeconds <= 5 ? Color.orange : Color.primary,
                                style: StrokeStyle(lineWidth: 6, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .frame(width: 88, height: 88)
                            .animation(.linear(duration: 1.0), value: viewModel.remainingSeconds)
                        
                        VStack(spacing: 0) {
                            Text("\(viewModel.remainingSeconds)")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(viewModel.remainingSeconds <= 5 ? Color.orange : Color.primary)
                            Text("sec")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.top, 4)
                    
                    VStack(spacing: 4) {
                        Text("\(broadcast.acceptedCount) of \(broadcast.staffNeeded) officers joined")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        
                        Text("Awaiting responses from nearby personnel...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    ProgressView(value: Double(broadcast.acceptedCount), total: Double(broadcast.staffNeeded))
                        .tint(broadcast.isFull ? .green : .primary)
                }
                
                // Accepted List Preview
                if !broadcast.acceptedStaff.isEmpty {
                    Divider()
                        .opacity(0.5)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Joined Officers")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                        
                        ForEach(broadcast.acceptedStaff) { staff in
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text(staff.name)
                                    .font(.subheadline.weight(.medium))
                                Spacer()
                                Text("Ready")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                
            } else if broadcast.status == .closed && broadcast.acceptedCount == 0 {
                // Page 3: 0 accepted -> show "Try again"
                VStack(spacing: 12) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 36))
                        .foregroundStyle(.secondary)
                    
                    VStack(spacing: 2) {
                        Text("No Staff Responded")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        Text("The 20-second acceptance window expired without any responses.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 12)
                    
                    Button {
                        viewModel.tryAgain()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.clockwise")
                                .font(.subheadline.weight(.semibold))
                            Text("Try Again")
                                .font(.body.weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .foregroundStyle(Color(uiColor: .systemBackground))
                        .background(Color.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .padding(.top, 4)
                }
                .padding(.vertical, 8)
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    // MARK: - Manager Page 4: Accepted Staff List & Finish Card
    @ViewBuilder
    private func page4DelegationCard(broadcast: BroadcastSession) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header Progress
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(broadcast.completedCount) of \(broadcast.acceptedCount) Completed")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text("Delegation in Progress")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if broadcast.isAllCompleted {
                    Text("All Done")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.green.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
            
            ProgressView(value: Double(broadcast.completedCount), total: max(1.0, Double(broadcast.acceptedCount)))
                .tint(broadcast.isAllCompleted ? .green : .blue)
            
            Divider()
                .opacity(0.5)
            
            // List of Accepted Staff Members
            VStack(alignment: .leading, spacing: 8) {
                Text("Assigned Officers")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                
                ForEach(broadcast.acceptedStaff) { item in
                    HStack(spacing: 12) {
                        Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "person.crop.circle.badge.clock.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(item.isCompleted ? Color.green : Color.blue)
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text(item.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                            
                            Text(item.isCompleted ? "Task completed" : "Active on duty")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        if !item.isCompleted {
                            Button {
                                viewModel.simulateStaffComplete(staffId: item.staffId)
                            } label: {
                                Text("Mark Done")
                                    .font(.caption.weight(.medium))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .foregroundStyle(Color(uiColor: .systemBackground))
                                    .background(Color.primary)
                                    .clipShape(Capsule())
                            }
                        } else {
                            Image(systemName: "checkmark")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.green)
                                .padding(.trailing, 4)
                        }
                    }
                    .padding(10)
                    .background(Color(uiColor: .tertiarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
            
            // Finish Broadcast Button (POST /broadcasts/{id}/finish)
            Button {
                viewModel.finishBroadcast()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.subheadline.weight(.semibold))
                    Text("Finish Delegation")
                        .font(.body.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .foregroundStyle(broadcast.isAllCompleted ? Color(uiColor: .systemBackground) : Color.secondary)
                .background(broadcast.isAllCompleted ? Color.primary : Color(uiColor: .tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .disabled(!broadcast.isAllCompleted)
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    // MARK: - Unobtrusive Simulation Controls
    @ViewBuilder
    private var simulationDrawer: some View {
        DisclosureGroup(isExpanded: $isSimulationExpanded) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Simulate staff receiving push notification and accepting:")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                if let broadcast = viewModel.broadcast, broadcast.status == .open {
                    let candidates = viewModel.availableStaffForSimulation
                    if candidates.isEmpty {
                        Text("All staff have already responded.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    } else {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            ForEach(candidates) { staff in
                                Button {
                                    viewModel.simulateStaffAccept(staffId: staff.id)
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "hand.tap.fill")
                                            .font(.caption2)
                                        Text("Accept: \(staff.name)")
                                            .font(.caption.weight(.medium))
                                            .lineLimit(1)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 36)
                                    .foregroundStyle(Color.primary)
                                    .background(Color(uiColor: .tertiarySystemGroupedBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                } else {
                    Text("Active only when broadcast is open.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 8)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "wrench.and.screwdriver")
                    .font(.caption2)
                Text("Staff Simulation (Testing)")
                    .font(.footnote.weight(.medium))
            }
            .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
    
    @ViewBuilder
    private func statusPill(status: BroadcastStatus) -> some View {
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
    
    private func statusColor(for status: BroadcastStatus) -> Color {
        switch status {
        case .open: return .blue
        case .closed: return .orange
        case .finished: return .green
        }
    }
}
