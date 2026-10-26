import SwiftUI

public struct AssignmentStatusView: View {
    @Bindable var viewModel: AssignmentStatusViewModel
    
    public init(viewModel: AssignmentStatusViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let request = viewModel.request {
                    // Main Status Card
                    VStack(spacing: 16) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(viewModel.destinationZone?.name ?? "Venue Zone")
                                    .font(.title3.weight(.bold))
                                    .foregroundStyle(.primary)
                                
                                Text("Deployment #\(viewModel.requestID.uuidString.prefix(6).uppercased())")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            statusBadge(for: request.status)
                        }
                        
                        Divider()
                            .opacity(0.5)
                        
                        // Assigned Staff Section
                        if request.status == .accepted, let staff = viewModel.assignedStaff {
                            VStack(alignment: .leading, spacing: 14) {
                                HStack(spacing: 12) {
                                    Image(systemName: "person.crop.circle.fill")
                                        .font(.system(size: 36))
                                        .foregroundStyle(.secondary)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(staff.name)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(.primary)
                                        Text("Assigned Officer")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Text("On Site")
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(.green)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Color.green.opacity(0.12))
                                        .clipShape(Capsule())
                                }
                                
                                if let assignment = viewModel.confirmedAssignment {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text("Progress")
                                                .font(.caption2.weight(.medium))
                                                .foregroundStyle(.secondary)
                                            Spacer()
                                            Text(assignment.progress.rawValue)
                                                .font(.caption2.weight(.semibold))
                                                .foregroundStyle(.primary)
                                        }
                                        
                                        progressStepBar(current: assignment.progress)
                                        
                                        if assignment.progress != .completed {
                                            Button {
                                                viewModel.advanceProgress()
                                            } label: {
                                                HStack(spacing: 6) {
                                                    Text("Advance: \(nextProgressLabel(current: assignment.progress))")
                                                        .font(.subheadline.weight(.medium))
                                                    Image(systemName: "chevron.right")
                                                        .font(.caption2.weight(.bold))
                                                }
                                                .frame(maxWidth: .infinity)
                                                .frame(height: 40)
                                                .foregroundStyle(Color(uiColor: .systemBackground))
                                                .background(Color.primary)
                                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                            }
                                            .padding(.top, 4)
                                        }
                                    }
                                }
                            }
                        } else {
                            // Concise Status Message
                            HStack(spacing: 12) {
                                Image(systemName: statusIcon(for: request.status))
                                    .font(.title3)
                                    .foregroundStyle(statusTextColor(for: request.status))
                                
                                Text(statusMessage(for: request.status))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(16)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    
                    // Return Action
                    Button {
                        viewModel.navigateToZoneDetail()
                    } label: {
                        Text("Back to Zone")
                            .font(.subheadline.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .foregroundStyle(.primary)
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .padding(.horizontal, 16)
                } else {
                    ContentUnavailableView(
                        "Record Not Found",
                        systemImage: "doc.text.magnifyingglass",
                        description: Text("Assignment record could not be found.")
                    )
                    .padding(24)
                }
                
                Spacer(minLength: 32)
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Assignment")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Helpers
    
    @ViewBuilder
    private func statusBadge(for status: RequestStatus) -> some View {
        Text(status.rawValue.capitalized)
            .font(.caption.weight(.medium))
            .foregroundStyle(statusTextColor(for: status))
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(statusBackgroundColor(for: status))
            .clipShape(Capsule())
    }
    
    private func statusMessage(for status: RequestStatus) -> String {
        switch status {
        case .pending:
            return "Awaiting staff response."
        case .expired:
            return "Response window expired."
        case .declined:
            return "Staff member declined the assignment."
        case .cancelled:
            return "Assignment was cancelled."
        case .accepted:
            return "Staff member accepted."
        }
    }
    
    private func statusIcon(for status: RequestStatus) -> String {
        switch status {
        case .accepted:
            return "checkmark.circle.fill"
        case .pending:
            return "clock.fill"
        case .expired:
            return "hourglass.bottomhalf.filled"
        case .declined:
            return "xmark.circle.fill"
        case .cancelled:
            return "slash.circle.fill"
        }
    }
    
    private func statusTextColor(for status: RequestStatus) -> Color {
        switch status {
        case .accepted: return .green
        case .pending: return .blue
        case .expired: return .orange
        case .declined: return .red
        case .cancelled: return .secondary
        }
    }
    
    private func statusBackgroundColor(for status: RequestStatus) -> Color {
        statusTextColor(for: status).opacity(0.12)
    }
    
    @ViewBuilder
    private func progressStepBar(current: AssignmentProgressStatus) -> some View {
        let steps: [AssignmentProgressStatus] = [.accepted, .onTheWay, .onSite, .completed]
        let currentIndex = steps.firstIndex(of: current) ?? 0
        
        HStack(spacing: 4) {
            ForEach(0..<steps.count, id: \.self) { index in
                Rectangle()
                    .fill(index <= currentIndex ? Color.primary : Color.primary.opacity(0.1))
                    .frame(height: 4)
                    .clipShape(Capsule())
            }
        }
    }
    
    private func nextProgressLabel(current: AssignmentProgressStatus) -> String {
        switch current {
        case .accepted: return "On The Way"
        case .onTheWay: return "On Site"
        case .onSite: return "Complete"
        case .completed: return "Done"
        }
    }
}
