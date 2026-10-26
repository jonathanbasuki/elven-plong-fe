import SwiftUI

struct ContentView: View {
    @State private var role: UserRole = .manager
    @State private var managerPage = 0
    @State private var staffPage = 0
    @State private var showingBroadcast = false
    @State private var staffNeeded = 4
    @State private var confirmedStaff = 0
    @State private var doneStaff = 0
    @State private var broadcastSecondsLeft = 20
    @State private var staffStatus: StaffStatus = .notDelegating

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    RolePicker(role: $role)
                    if role == .manager {
                        ManagerFlow(page: $managerPage, confirmedStaff: confirmedStaff, staffNeeded: staffNeeded, doneStaff: doneStaff, broadcastSecondsLeft: $broadcastSecondsLeft, startBroadcast: startBroadcast) {
                            showingBroadcast = true
                        }
                    } else {
                        StaffFlow(page: $staffPage, status: $staffStatus) {
                            doneStaff = min(doneStaff + 1, confirmedStaff)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Plong")
            .sheet(isPresented: $showingBroadcast) {
                BroadcastSheet(staffNeeded: $staffNeeded) {
                    showingBroadcast = false
                    confirmedStaff = 0
                    doneStaff = 0
                    broadcastSecondsLeft = 20
                    managerPage = 1
                }
                .presentationDetents([.medium])
            }
        }
    }

    private func startBroadcast() {
        confirmedStaff = 0
        doneStaff = 0
        broadcastSecondsLeft = 20
    }
}

enum UserRole: String, CaseIterable {
    case manager = "Manager"
    case staff = "Staff"
}

struct RolePicker: View {
    @Binding var role: UserRole

    var body: some View {
        HStack(spacing: 8) {
            ForEach(UserRole.allCases, id: \.self) { item in
                Button(item.rawValue) { role = item }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(role == item ? .white : .primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(role == item ? Color.primary : Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(Capsule())
            }
        }
    }
}

struct PageHeader: View {
    let eyebrow: String
    let title: String
    let page: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(eyebrow.uppercased()).font(.caption.weight(.bold)).foregroundStyle(.secondary)
            Text(title).font(.system(size: 30, weight: .bold, design: .rounded))
            Text("0\(page + 1) / 03").font(.caption.monospaced()).foregroundStyle(.secondary)
        }
    }
}

struct ManagerFlow: View {
    @Binding var page: Int
    let confirmedStaff: Int
    let staffNeeded: Int
    let doneStaff: Int
    @Binding var broadcastSecondsLeft: Int
    let startBroadcast: () -> Void
    let broadcast: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            PageHeader(eyebrow: "Manager", title: ["Overview", "Looking for staff", "Task progress"][page], page: page)
            if page == 0 {
                HStack(spacing: 12) {
                    StatCard(label: "Total crowd", value: "1,248", icon: "person.3.fill")
                    StatCard(label: "Peak", value: "18:40", icon: "chart.line.uptrend.xyaxis")
                }
                CCTVPlaceholder()
                PrimaryButton(title: "Broadcast task", icon: "paperplane.fill", action: broadcast)
            } else if page == 1 {
                StatusCard(title: "Staff confirmed", value: "\(confirmedStaff) / \(staffNeeded)", detail: broadcastSecondsLeft > 0 ? "Broadcast closes in \(broadcastSecondsLeft)s" : "Broadcast closed", progress: Double(confirmedStaff) / Double(staffNeeded))
                if broadcastSecondsLeft == 0 && confirmedStaff == 0 {
                    PrimaryButton(title: "Try again", action: startBroadcast)
                }
                if broadcastSecondsLeft == 0 && confirmedStaff >= 1 {
                    PrimaryButton(title: "View progress", action: { page = 2 })
                }
            } else {
                let progress = confirmedStaff == 0 ? 0 : Double(doneStaff) / Double(confirmedStaff)
                StatusCard(title: "Task progress", value: "\(doneStaff) / \(confirmedStaff) staff done", detail: "Accepted staff", progress: progress)
                PrimaryButton(title: "Finish", action: { page = 0 })
                    .disabled(doneStaff != confirmedStaff || confirmedStaff < 1)
            }
        }
        .task(id: page == 1 ? broadcastSecondsLeft : -1) {
            guard page == 1, broadcastSecondsLeft > 0 else { return }
            try? await Task.sleep(for: .seconds(1))
            if !Task.isCancelled { broadcastSecondsLeft -= 1 }
        }
    }
}

enum StaffStatus {
    case notDelegating
    case delegating
    case done
}

struct StaffFlow: View {
    @Binding var page: Int
    @Binding var status: StaffStatus
    let markDone: () -> Void
    @State private var secondsLeft = 20

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            PageHeader(eyebrow: "Staff", title: status == .delegating ? "Your task" : "New task", page: page)
            if status == .notDelegating {
                TaskCard(secondsLeft: secondsLeft) {
                    status = .delegating
                    page = 1
                }
                .onAppear { secondsLeft = 20 }
                .task {
                    while secondsLeft > 0 && status == .notDelegating {
                        try? await Task.sleep(for: .seconds(1))
                        secondsLeft -= 1
                    }
                }
            } else {
                StatusCard(title: "Crowd control", value: status == .done ? "Done" : "In progress", detail: "Zone B · Central gate", progress: status == .done ? 1 : 0.45)
                PrimaryButton(title: "Mark as done", icon: "checkmark", action: {
                    markDone()
                    status = .done
                })
                .disabled(status != .delegating)
            }
        }
    }
}

struct BroadcastSheet: View {
    @Binding var staffNeeded: Int
    let send: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Broadcast task").font(.title2.bold())
            Stepper("\(staffNeeded) staff needed", value: $staffNeeded, in: 1...20)
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            PrimaryButton(title: "Send task", action: send)
        }
        .padding(24)
    }
}

struct TaskCard: View {
    let secondsLeft: Int
    let accept: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Label("New task", systemImage: "bell.fill")
                    .font(.headline)
                Spacer()
                Text("00:\(String(format: "%02d", secondsLeft))")
                    .font(.headline.monospacedDigit())
            }
            Divider()
            Text("Crowd control")
                .font(.title3.bold())
            Text("Zone B · Central gate")
                .foregroundStyle(.secondary)
            PrimaryButton(title: "Accept task", action: accept)
        }
        .padding(20)
        .cardStyle()
    }
}

struct CCTVPlaceholder: View {
    var body: some View {
        ZStack {
            Rectangle().fill(Color.black)
            VStack(spacing: 10) {
                Image(systemName: "video.fill").font(.title)
                Text("LIVE CCTV").font(.caption.weight(.bold).monospaced())
            }
            .foregroundStyle(.white.opacity(0.75))
        }
        .frame(height: 190)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(alignment: .topLeading) {
            Text("CAM 01").font(.caption2.monospaced()).foregroundStyle(.white).padding(12)
        }
    }
}

struct StatCard: View {
    let label: String; let value: String; let icon: String
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon).foregroundStyle(.secondary)
            Text(value).font(.title2.bold())
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16).cardStyle()
    }
}

struct StatusCard: View {
    let title: String; let value: String; let detail: String; let progress: Double
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title).font(.headline)
            Text(value).font(.system(size: 34, weight: .bold, design: .rounded))
            Text(detail).font(.subheadline).foregroundStyle(.secondary)
            ProgressView(value: progress).tint(.primary)
        }.padding(20).cardStyle()
    }
}

struct ProgressRow: View {
    let name: String; let status: String; let progress: Double
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack { Text(name).font(.subheadline.bold()); Spacer(); Text(status).font(.caption).foregroundStyle(.secondary) }
            ProgressView(value: progress).tint(.primary)
        }
    }
}

struct PrimaryButton: View {
    let title: String; var icon: String? = nil; let action: () -> Void
    var body: some View { Button(action: action) { Label(title, systemImage: icon ?? "arrow.right").frame(maxWidth: .infinity) }.buttonStyle(.borderedProminent).tint(.primary).controlSize(.large) }
}

struct SecondaryButton: View {
    let title: String; let action: () -> Void
    var body: some View { Button(title, action: action).frame(maxWidth: .infinity).buttonStyle(.bordered).tint(.primary).controlSize(.large) }
}

extension View {
    func cardStyle() -> some View { background(Color(uiColor: .secondarySystemGroupedBackground)).clipShape(RoundedRectangle(cornerRadius: 18)) }
}

#Preview { ContentView() }
