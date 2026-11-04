import SwiftUI

public enum ZoneModalStep: Equatable {
    case detail
    case waiting
    case confirmed
}

/// Zone Detail & Delegation Modal Sheet matching sample/Manager/modal detail.svg,
/// modal delegate waiting.svg, and modal delegate done.svg.
/// Conforms to Apple HIG: clean native presentation, no redundant grabbers, and easy keyboard dismissal.
public struct ZoneDetailModalView: View {
    public let zone: VenueZone
    public let availableStaffCount: Int
    public let onDismiss: () -> Void
    public let onConfirmDelegation: (VenueZone, Int, String) -> Void
    
    @State private var step: ZoneModalStep = .detail
    @State private var staffNeeded: Int = 5
    @State private var instructionText: String = ""
    @State private var remainingSeconds: Int = 20
    @State private var acceptedStaffCount: Int = 0
    @State private var timer: Timer? = nil
    @FocusState private var isInstructionFocused: Bool
    
    public init(
        zone: VenueZone,
        availableStaffCount: Int = 2,
        onDismiss: @escaping () -> Void,
        onConfirmDelegation: @escaping (VenueZone, Int, String) -> Void
    ) {
        self.zone = zone
        self.availableStaffCount = availableStaffCount
        self.onDismiss = onDismiss
        self.onConfirmDelegation = onConfirmDelegation
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            switch step {
            case .detail:
                detailContentView
            case .waiting:
                waitingContentView
            case .confirmed:
                confirmedContentView
            }
        }
        .background(Color(uiColor: .systemBackground))
        .onDisappear {
            stopTimer()
        }
        // Keyboard dismissal when tapping anywhere outside input
        .onTapGesture {
            dismissKeyboard()
        }
    }
    
    // MARK: - Step 1: Zone Detail Content (modal zone.svg & modal detail.svg)
    private var detailContentView: some View {
        VStack(spacing: 0) {
            // Header Bar: Clean native spacing below iOS grabber
            ZStack {
                Text(zone.name)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color(uiColor: .label))
                    .accessibilityAddTraits(.isHeader)
                
                HStack {
                    Spacer()
                    
                    Button {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        dismissKeyboard()
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color(uiColor: .label))
                            .frame(width: 36, height: 36)
                            .background(Color(uiColor: .secondarySystemFill))
                            .clipShape(Circle())
                            .frame(width: 44, height: 44) // HIG hit target
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Close modal")
                }
            }
            .padding(.top, 22) // Space below native presentation drag indicator
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Status and Crowd Count Row
                    HStack(spacing: 0) {
                        VStack(spacing: 4) {
                            Text("Status")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color(uiColor: .secondaryLabel))
                            
                            Text("Overflow")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(Color(red: 0.85, green: 0.20, blue: 0.20))
                        }
                        .frame(maxWidth: .infinity)
                        
                        VStack(spacing: 4) {
                            Text("Crowd Count")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color(uiColor: .secondaryLabel))
                            
                            Text("\(zone.currentCount)")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(Color(uiColor: .label))
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.top, 4)
                    
                    // CCTV Live Snapshot
                    Image("cctv_snapshot")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.06), radius: 6, y: 3)
                    
                    // Active Staff in Area Section with user profile image
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Active Staff in Area")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color(uiColor: .secondaryLabel))
                        
                        staffRow(name: "Rendi Septrian", role: "Security", statusText: "Onsite • Pantry")
                        Divider().opacity(0.4)
                        staffRow(name: "Rendi Septrian", role: "Security", statusText: "Onsite • Pantry")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Task Instruction Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Task Instruction :")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color(uiColor: .label))
                        
                        TextField("ex : fix the overflow crowd", text: $instructionText, axis: .vertical)
                            .lineLimit(3...5)
                            .focused($isInstructionFocused)
                            .font(.system(size: 14))
                            .padding(14)
                            .background(Color(uiColor: .systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.primary.opacity(0.18), lineWidth: 1)
                            )
                    }
                    
                    // Staff Needed Stepper Section
                    VStack(spacing: 8) {
                        Text("Staff needed")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color(uiColor: .label))
                        
                        HStack(spacing: 28) {
                            Button {
                                if staffNeeded > 1 {
                                    let impact = UIImpactFeedbackGenerator(style: .light)
                                    impact.impactOccurred()
                                    staffNeeded -= 1
                                }
                            } label: {
                                Image(systemName: "minus")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(Color(uiColor: .label))
                                    .frame(width: 36, height: 36)
                                    .background(Color(uiColor: .systemGray5))
                                    .clipShape(Circle())
                                    .frame(width: 44, height: 44) // HIG hit target
                                    .contentShape(Rectangle())
                            }
                            .disabled(staffNeeded <= 1)
                            .accessibilityLabel("Decrease staff needed")
                            
                            Text("\(staffNeeded)")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(Color(uiColor: .label))
                                .frame(minWidth: 32)
                            
                            Button {
                                if staffNeeded < 10 {
                                    let impact = UIImpactFeedbackGenerator(style: .light)
                                    impact.impactOccurred()
                                    staffNeeded += 1
                                }
                            } label: {
                                Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(Color(uiColor: .label))
                                    .frame(width: 36, height: 36)
                                    .background(Color(uiColor: .systemGray5))
                                    .clipShape(Circle())
                                    .frame(width: 44, height: 44) // HIG hit target
                                    .contentShape(Rectangle())
                            }
                            .disabled(staffNeeded >= 10)
                            .accessibilityLabel("Increase staff needed")
                        }
                    }
                    .padding(.top, 4)
                    
                    // Add Staff Primary Button
                    PrimaryPillButton(title: "Add Staff") {
                        dismissKeyboard()
                        startDelegationProcess()
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 20)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }
    
    // MARK: - Step 2: Waiting Content (modal delegate waiting.svg)
    private var waitingContentView: some View {
        VStack(spacing: 0) {
            Text(zone.name)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color(uiColor: .label))
                .padding(.top, 24)
            
            Spacer()
            
            VStack(spacing: 16) {
                ProgressView()
                    .controlSize(.large)
                    .scaleEffect(1.4)
                    .tint(Color(uiColor: .label))
                    .padding(.bottom, 8)
                
                Text("Gathering Staff for")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color(uiColor: .secondaryLabel))
                
                Text("Crowd Control")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Color(uiColor: .label))
                
                Text("Time remaining : \(remainingSeconds) sec")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(Color(uiColor: .secondaryLabel))
            }
            
            Spacer()
            
            Button {
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
                cancelDelegation()
            } label: {
                Text("Cancel")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(red: 0.95, green: 0.20, blue: 0.20))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color(red: 0.98, green: 0.88, blue: 0.88))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
        .frame(minHeight: 380)
    }
    
    // MARK: - Step 3: Confirmed Content (modal delegate done.svg)
    private var confirmedContentView: some View {
        VStack(spacing: 0) {
            Text(zone.name)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color(uiColor: .label))
                .padding(.top, 24)
            
            Spacer()
            
            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color(uiColor: .systemGray5))
                        .frame(width: 58, height: 58)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(Color(uiColor: .secondaryLabel))
                }
                .padding(.bottom, 6)
                
                Text("Task Confirmed")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Color(uiColor: .label))
                
                Text("\(staffNeeded)/\(staffNeeded) Staff Assigned")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color(uiColor: .secondaryLabel))
            }
            
            Spacer()
            
            PrimaryPillButton(title: "Done") {
                let notification = UINotificationFeedbackGenerator()
                notification.notificationOccurred(.success)
                onConfirmDelegation(zone, staffNeeded, instructionText)
                onDismiss()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
        .frame(minHeight: 380)
    }
    
    // MARK: - Helper Staff Row (Uses user_profile image)
    private func staffRow(name: String, role: String, statusText: String) -> some View {
        HStack(spacing: 14) {
            Image("user_profile")
                .resizable()
                .scaledToFill()
                .frame(width: 48, height: 48)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.primary.opacity(0.1), lineWidth: 1))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(uiColor: .label))
                
                Text(role)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color(uiColor: .secondaryLabel))
            }
            
            Spacer()
            
            Text(statusText)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Color(uiColor: .secondaryLabel))
        }
    }
    
    // MARK: - Actions & Timer
    private func dismissKeyboard() {
        isInstructionFocused = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func startDelegationProcess() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        step = .waiting
        remainingSeconds = 20
        acceptedStaffCount = 0
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                if self.remainingSeconds > 0 {
                    self.remainingSeconds -= 1
                    
                    // Progressive response simulation:
                    if self.remainingSeconds % 2 == 0 && self.acceptedStaffCount < self.staffNeeded {
                        self.acceptedStaffCount += 1
                    }
                    
                    // If target staff is reached before 20s, proceed immediately
                    if self.acceptedStaffCount >= self.staffNeeded {
                        self.transitionToConfirmed()
                    }
                } else {
                    self.transitionToConfirmed()
                }
            }
        }
    }
    
    private func transitionToConfirmed() {
        stopTimer()
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.success)
        withAnimation(.easeInOut(duration: 0.3)) {
            self.step = .confirmed
        }
    }
    
    private func cancelDelegation() {
        stopTimer()
        withAnimation(.easeInOut(duration: 0.25)) {
            self.step = .detail
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

#Preview {
    ZoneDetailModalView(
        zone: VenueZone(
            id: "z1",
            name: "Pantry Academy",
            currentCount: 50,
            warningThreshold: 20,
            crowdedThreshold: 35
        ),
        availableStaffCount: 2,
        onDismiss: {},
        onConfirmDelegation: { _, _, _ in }
    )
}
