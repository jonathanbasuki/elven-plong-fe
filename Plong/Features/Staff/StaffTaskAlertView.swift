import SwiftUI
import AudioToolbox

/// Staff Task Incoming Alert View matching sample/staff/alertstaff.png.
/// Pops up on the staff device with haptic & sound when a task is dispatched by the manager.
public struct StaffTaskAlertView: View {
    public let task: TaskLogItem
    public let onAccept: (TaskLogItem) -> Void
    public var onDismiss: (() -> Void)? = nil
    
    public init(
        task: TaskLogItem,
        onAccept: @escaping (TaskLogItem) -> Void,
        onDismiss: (() -> Void)? = nil
    ) {
        self.task = task
        self.onAccept = onAccept
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        ZStack {
            // Dark solid background matching sample/staff/alertstaff.png
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top close action if dismissable
                HStack {
                    Spacer()
                    if let onDismiss = onDismiss {
                        Button {
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred()
                            onDismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(.white.opacity(0.7))
                                .frame(width: 36, height: 36)
                                .background(Color.white.opacity(0.12))
                                .clipShape(Circle())
                        }
                        .padding(.top, 16)
                        .padding(.trailing, 20)
                    }
                }
                
                Spacer()
                
                // Centered Alert Content
                VStack(spacing: 0) {
                    // Triangle Warning Icon
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 68, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.bottom, 28)
                        .shadow(color: Color.white.opacity(0.2), radius: 12)
                    
                    // Brand / App Name
                    Text("Plong")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.bottom, 6)
                    
                    // Zone Issue Headline
                    Text(task.title.isEmpty ? "Overflow in Pantry Academy" : task.title)
                        .font(.system(size: 21, weight: .semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                        .padding(.bottom, 28)
                    
                    // Details (Date & Location)
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 12) {
                            Image(systemName: "doc.text")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(.white.opacity(0.75))
                                .frame(width: 24)
                            
                            Text(task.formattedDateTime.isEmpty ? "Sun, 5 okt 2026 - 1:24 PM" : task.formattedDateTime)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.white.opacity(0.85))
                        }
                        
                        HStack(spacing: 12) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(.white.opacity(0.75))
                                .frame(width: 24)
                            
                            Text(task.locationName.isEmpty ? "Pantry Academy" : task.locationName)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.white.opacity(0.85))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 38)
                }
                
                Spacer()
                
                // Bottom "Accept Task" Action Button
                Button {
                    let notification = UINotificationFeedbackGenerator()
                    notification.notificationOccurred(.success)
                    onAccept(task)
                } label: {
                    Text("Accept Task")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color(red: 0.0, green: 0.48, blue: 1.0))
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 36)
                .accessibilityLabel("Accept Task: \(task.title)")
            }
        }
        .onAppear {
            triggerAlertFeedback()
        }
    }
    
    private func triggerAlertFeedback() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
}

#Preview {
    StaffTaskAlertView(
        task: TaskLogItem(
            title: "Overflow in Pantry Academy",
            dateString: "5 okt 2026",
            timeString: "1:24 PM",
            status: .ongoing,
            locationName: "Pantry Academy"
        ),
        onAccept: { _ in }
    )
}

