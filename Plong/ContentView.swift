import AVKit
import SwiftUI

struct ContentView: View {
    @StateObject private var session = Session()

    var body: some View {
        NavigationStack {
            Group {
                if session.accessToken == nil || session.zoneId == nil {
                    LoginView()
                } else if session.isManager {
                    ManagerContainer()
                } else {
                    StaffContainer()
                }
            }
            .navigationTitle("Plong")
            .toolbar {
                if session.accessToken != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Log out", action: session.logOut)
                    }
                }
            }
        }
        .environmentObject(session)
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

struct ManagerContainer: View {
    @EnvironmentObject var session: Session
    @State private var page = 0
    @State private var showingBroadcast = false
    @State private var staffNeeded = 4
    @State private var createError: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                PageHeader(
                    eyebrow: "Manager",
                    title: ["Overview", "Looking for staff", "Task progress"][page],
                    page: page
                )
                if page == 0 {
                    ManagerOverviewPage { showingBroadcast = true }
                } else if page == 1 {
                    ManagerWaitingPage(
                        page: $page,
                        startBroadcast: { showingBroadcast = true }
                    )
                } else {
                    ManagerProgressPage(page: $page)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .sheet(isPresented: $showingBroadcast) {
            BroadcastSheet(staffNeeded: $staffNeeded, errorMessage: createError) {
                Task {
                    createError = nil
                    do {
                        guard let token = session.accessToken, let zoneId = session.zoneId else { return }
                        _ = try await API.createBroadcast(zoneId: zoneId, staffNeeded: staffNeeded, token: token)
                        showingBroadcast = false
                        page = 1
                    } catch {
                        createError = (error as? APIError)?.message ?? "Could not start broadcast"
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }
}

struct ManagerOverviewPage: View {
    @EnvironmentObject var session: Session
    @State private var zone: ZoneStat?
    let broadcast: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                StatCard(label: "Total crowd", value: zone.map { "\($0.currentCount)" } ?? "-", icon: "person.3.fill")
                StatCard(label: "Status", value: (zone?.status ?? "-").capitalized, icon: "chart.line.uptrend.xyaxis")
            }
            CCTVPreview()
            PrimaryButton(title: "Broadcast task", icon: "paperplane.fill", action: broadcast)
        }
        .task {
            while !Task.isCancelled {
                if let token = session.accessToken, let zoneId = session.zoneId {
                    zone = try? await API.getZone(zoneId: zoneId, token: token)
                }
                try? await Task.sleep(for: .seconds(2))
            }
        }
    }
}

struct ManagerWaitingPage: View {
    @EnvironmentObject var session: Session
    @Binding var page: Int
    let startBroadcast: () -> Void
    @State private var broadcast: BroadcastState?

    private var secondsLeft: Int {
        guard let broadcast else { return 0 }
        let remaining = ISO8601.parse(broadcast.expiresAt).timeIntervalSinceNow
        return max(0, Int(remaining.rounded(.up)))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            StatusCard(
                title: "Staff confirmed",
                value: "\(broadcast?.acceptedCount ?? 0) / \(broadcast?.staffNeeded ?? 0)",
                detail: secondsLeft > 0 ? "Broadcast closes in \(secondsLeft)s" : "Broadcast closed",
                progress: broadcast.map { Double($0.acceptedCount) / Double(max($0.staffNeeded, 1)) } ?? 0
            )
            if let broadcast, broadcast.status != "open" {
                if broadcast.acceptedCount == 0 {
                    PrimaryButton(title: "Try again", action: startBroadcast)
                } else {
                    PrimaryButton(title: "View progress", action: { page = 2 })
                }
            }
        }
        .task {
            while !Task.isCancelled {
                if let token = session.accessToken, let zoneId = session.zoneId {
                    broadcast = try? await API.getCurrentBroadcast(zoneId: zoneId, token: token)
                }
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }
}

struct ManagerProgressPage: View {
    @EnvironmentObject var session: Session
    @Binding var page: Int
    @State private var broadcast: BroadcastState?
    @State private var isFinishing = false

    var body: some View {
        let accepted = broadcast?.acceptedCount ?? 0
        let completed = broadcast?.completedCount ?? 0
        let progress = accepted == 0 ? 0 : Double(completed) / Double(accepted)
        VStack(alignment: .leading, spacing: 20) {
            StatusCard(
                title: "Task progress",
                value: "\(completed) / \(accepted) staff done",
                detail: "Accepted staff",
                progress: progress
            )
            PrimaryButton(title: isFinishing ? "Finishing..." : "Finish") {
                guard let broadcast, let token = session.accessToken else { return }
                isFinishing = true
                Task {
                    try? await API.finish(broadcastId: broadcast.broadcastId, token: token)
                    isFinishing = false
                    page = 0
                }
            }
            .disabled(isFinishing || completed != accepted || accepted < 1)
        }
        .task {
            while !Task.isCancelled {
                if let token = session.accessToken, let zoneId = session.zoneId {
                    broadcast = try? await API.getCurrentBroadcast(zoneId: zoneId, token: token)
                }
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }
}

enum StaffStatus {
    case notDelegating
    case delegating
    case done
}

struct StaffContainer: View {
    @EnvironmentObject var session: Session
    @State private var status: StaffStatus = .notDelegating
    @State private var broadcast: BroadcastState?
    @State private var secondsLeft = 20
    @State private var isActing = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                PageHeader(
                    eyebrow: "Staff",
                    title: status == .notDelegating ? "New task" : "Your task",
                    page: status == .notDelegating ? 0 : 1
                )
                if status == .notDelegating {
                    if broadcast?.status == "open" {
                        TaskCard(secondsLeft: secondsLeft, zoneId: session.zoneId ?? "-", accept: accept)
                    }
                } else {
                    StatusCard(
                        title: "Crowd control",
                        value: status == .done ? "Done" : "In progress",
                        detail: "Zone \(session.zoneId ?? "-")",
                        progress: status == .done ? 1 : 0.45
                    )
                    PrimaryButton(title: isActing ? "Marking done..." : "Mark as done", icon: "checkmark", action: markDone)
                        .disabled(status != .delegating || isActing)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .task { await poll() }
    }

    private func poll() async {
        while !Task.isCancelled {
            if let token = session.accessToken, let userId = session.user?.id, let zoneId = session.zoneId {
                let current = try? await API.getCurrentBroadcast(zoneId: zoneId, token: token)
                broadcast = current

                if let mine = current?.acceptedStaff.first(where: { $0.staffId == userId }) {
                    status = mine.completedAt != nil ? .done : .delegating
                } else {
                    status = .notDelegating
                    if let expiresAt = current?.expiresAt, current?.status == "open" {
                        let remaining = ISO8601.parse(expiresAt).timeIntervalSinceNow
                        secondsLeft = max(0, Int(remaining.rounded(.up)))
                    }
                }
            }
            try? await Task.sleep(for: .seconds(1))
        }
    }

    private func accept() {
        guard let broadcast, let token = session.accessToken, !isActing else { return }
        isActing = true
        Task {
            try? await API.respond(broadcastId: broadcast.broadcastId, token: token)
            isActing = false
        }
    }

    private func markDone() {
        guard let broadcast, let token = session.accessToken, !isActing else { return }
        isActing = true
        Task {
            // No optimistic local update: poll() re-derives status from the server
            // every second, so a failed call here just leaves the button enabled
            // instead of silently showing a false "not delegating" state.
            try? await API.complete(broadcastId: broadcast.broadcastId, token: token)
            isActing = false
        }
    }
}

struct BroadcastSheet: View {
    @Binding var staffNeeded: Int
    let errorMessage: String?
    let send: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Broadcast task").font(.title2.bold())
            Stepper("\(staffNeeded) staff needed", value: $staffNeeded, in: 1...20)
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            if let errorMessage {
                Text(errorMessage).font(.footnote).foregroundStyle(.red)
            }
            PrimaryButton(title: "Send task", action: send)
        }
        .padding(24)
    }
}

struct TaskCard: View {
    let secondsLeft: Int
    let zoneId: String
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
            Text("Zone \(zoneId)")
                .foregroundStyle(.secondary)
            PrimaryButton(title: "Accept task", action: accept)
        }
        .padding(20)
        .cardStyle()
    }
}

struct CCTVPreview: View {
    // Fresh AVPlayer per appearance: avoids holding a stale/buffered player across
    // tab switches, at the cost of a short reconnect each time the page re-shows.
    @State private var player = AVPlayer(url: hlsURL)

    var body: some View {
        LivePlayerView(player: player)
            .frame(height: 190)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(alignment: .topLeading) {
                Text("CAM 01").font(.caption2.monospaced()).foregroundStyle(.white).padding(12)
            }
            .onAppear { player.play() }
            .onDisappear { player.pause() }
    }
}

/// AVPlayerViewController with controls hidden — VideoPlayer always shows a
/// pause/scrub bar with no way to disable just that, which would let a manager
/// pause the feed and mistake the frozen frame for "live".
struct LivePlayerView: UIViewControllerRepresentable {
    let player: AVPlayer

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false
        return controller
    }

    func updateUIViewController(_ controller: AVPlayerViewController, context: Context) {}
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
