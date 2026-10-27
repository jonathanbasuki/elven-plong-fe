import AVFoundation
import AVKit
import SwiftUI

/// GroupBox's default (.automatic) style doesn't reliably contrast against a
/// systemGroupedBackground screen in light mode — the two can render nearly
/// identical, which is why cards were blending into the background. This gives
/// every GroupBox in the app a real surface using secondarySystemGroupedBackground,
/// the semantic "card on top of a grouped background" color: it adapts
/// automatically per appearance (light gray in light mode, dark gray in dark
/// mode) rather than being a hardcoded color.
struct CardGroupBoxStyle: GroupBoxStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            configuration.label
            configuration.content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct ContentView: View {
    @StateObject private var session = Session()

    var body: some View {
        NavigationStack {
            Group {
                if session.isRestoringSession {
                    ProgressView()
                } else if session.accessToken == nil || session.zoneId == nil {
                    LoginView()
                } else if session.isManager {
                    ManagerContainer()
                } else {
                    StaffContainer()
                }
            }
            .navigationTitle("Plong")
            .toolbar(session.accessToken == nil ? .hidden : .visible, for: .navigationBar)
            .task {
                AppDelegate.session = session
                await session.restoreSession()
            }
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

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(eyebrow.uppercased()).font(.caption.weight(.bold)).foregroundStyle(.secondary)
            Text(title).font(.title.bold())
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
                    title: ["Overview", "Looking for staff", "Task progress"][page]
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
        .groupBoxStyle(CardGroupBoxStyle())
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

    // Ticks from the device clock every second, independent of the network poll below —
    // if a poll stalls (backgrounded app, slow network), the countdown keeps moving
    // instead of freezing at its last-fetched value.
    private static func secondsLeft(_ broadcast: BroadcastState?, _ now: Date) -> Int {
        guard let broadcast else { return 0 }
        let remaining = ISO8601.parse(broadcast.expiresAt).timeIntervalSince(now)
        return max(0, Int(remaining.rounded(.up)))
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let secondsLeft = Self.secondsLeft(broadcast, context.date)
            VStack(alignment: .leading, spacing: 20) {
                StatusCard(
                    title: "Staff confirmed",
                    value: "\(broadcast?.acceptedCount ?? 0) / \(broadcast?.staffNeeded ?? 0)",
                    detail: secondsLeft > 0 ? "Broadcast closes in \(secondsLeft)s" : "Broadcast closed",
                    progress: broadcast.map { Double($0.acceptedCount) / Double(max($0.staffNeeded, 1)) } ?? 0
                )
                if let broadcast {
                    if broadcast.acceptedCount > 0 {
                        // At least one person is on it — let the manager move on
                        // right away rather than waiting out the full countdown;
                        // more staff can still accept after this.
                        PrimaryButton(title: "Continue", action: { page = 2 })
                    } else if broadcast.status != "open" {
                        PrimaryButton(title: "Try again", action: startBroadcast)
                    }
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
    @State private var isActing = false

    // Ticks from the device clock every second, independent of the network poll below —
    // if a poll stalls (backgrounded app, slow network), the countdown keeps moving
    // instead of freezing at its last-fetched value.
    private static func secondsLeft(_ broadcast: BroadcastState?, _ now: Date) -> Int {
        guard let broadcast, broadcast.status == "open" else { return 0 }
        let remaining = ISO8601.parse(broadcast.expiresAt).timeIntervalSince(now)
        return max(0, Int(remaining.rounded(.up)))
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    PageHeader(
                        eyebrow: "Staff",
                        title: status == .delegating ? "Your task" : "New Task"
                    )
                    if status == .delegating {
                        StatusCard(
                            title: "Crowd control",
                            value: "In progress",
                            detail: "Zone \(session.zoneId ?? "-")",
                            progress: 0.45
                        )
                        SlideToConfirmButton(
                            title: isActing ? "Marking done..." : "Slide to mark done",
                            isActing: isActing,
                            action: markDone
                        )
                    } else if status == .notDelegating && broadcast?.status == "open" {
                        // .done deliberately excluded here even if the broadcast is
                        // still open for other staff — this person already finished
                        // their part, so they land on the empty state below, not a
                        // re-prompt to accept the same broadcast again.
                        TaskCard(
                            secondsLeft: Self.secondsLeft(broadcast, context.date),
                            zoneId: session.zoneId ?? "-", accept: accept
                        )
                    } else {
                        EmptyTaskState()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .groupBoxStyle(CardGroupBoxStyle())
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
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Stepper("\(staffNeeded) staff needed", value: $staffNeeded, in: 1...20)
                if let errorMessage {
                    Text(errorMessage).foregroundStyle(.red)
                }
            }
            .navigationTitle("Broadcast Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Send", action: send)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct TaskCard: View {
    let secondsLeft: Int
    let zoneId: String
    let accept: () -> Void

    var body: some View {
        GroupBox {
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
                PrimaryButton(title: "Accept Task", action: accept)
            }
        }
    }
}

/// Apple has no public API for a continuous slide-to-confirm/unlock gesture — the
/// classic iPhone lock-screen slider was always a private control, never exposed to
/// third-party apps, so this stays custom. Styled with native materials/colors
/// (.thinMaterial track, Color.accentColor handle, SF Symbols chevron) rather than
/// hardcoded colors, and modeled on the original: a round handle you drag along a
/// full-width track, not a tap target.
struct SlideToConfirmButton: View {
    let title: String
    let isActing: Bool
    let action: () -> Void
    @State private var dragOffset: CGFloat = 0
    @State private var confirmed = false

    private let trackHeight: CGFloat = 72
    private let handleSize: CGFloat = 62

    var body: some View {
        GeometryReader { geo in
            let maxOffset = max(geo.size.width - handleSize - 8, 0)
            ZStack(alignment: .leading) {
                Capsule().fill(Color(uiColor: .secondarySystemGroupedBackground))
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .opacity(confirmed ? 0 : 1)
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: handleSize, height: handleSize)
                    .overlay(
                        Image(systemName: "chevron.right")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                    )
                    .offset(x: 4 + dragOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                guard !confirmed, !isActing else { return }
                                dragOffset = min(max(0, value.translation.width), maxOffset)
                            }
                            .onEnded { value in
                                guard !confirmed, !isActing else { return }
                                if dragOffset >= maxOffset * 0.9 {
                                    confirmed = true
                                    dragOffset = maxOffset
                                    action()
                                } else {
                                    withAnimation(.spring()) { dragOffset = 0 }
                                }
                            }
                    )
            }
        }
        .frame(height: trackHeight)
    }
}

struct EmptyTaskState: View {
    var body: some View {
        ContentUnavailableView(
            "No active task",
            systemImage: "tray",
            description: Text("You'll be notified when a new broadcast opens.")
        )
    }
}

struct CCTVPreview: View {
    // Fresh AVPlayer per appearance: avoids holding a stale/buffered player across
    // tab switches, at the cost of a short reconnect each time the page re-shows.
    @State private var player = AVPlayer(url: hlsURL)

    var body: some View {
        GroupBox {
            LivePlayerView(player: player)
                .frame(height: 190)
                .overlay(alignment: .topLeading) {
                    Text("CAM 01").font(.caption2.monospaced()).foregroundStyle(.white).padding()
                }
        }
        .onAppear {
            // Muting alone isn't enough — AVPlayer still activates an audio session
            // that, by default, stops whatever else is playing (e.g. Music/Spotify).
            // .ambient + .mixWithOthers tells iOS this app never needs audio focus.
            try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
            try? AVAudioSession.sharedInstance().setActive(true)
            player.isMuted = true
            player.play()
        }
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
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: icon).foregroundStyle(.secondary)
                Text(value).font(.title2.bold())
                Text(label).font(.caption).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct StatusCard: View {
    let title: String; let value: String; let detail: String; let progress: Double
    var body: some View {
        GroupBox(title) {
            VStack(alignment: .leading, spacing: 14) {
                Text(value).font(.largeTitle.bold())
                Text(detail).font(.subheadline).foregroundStyle(.secondary)
                ProgressView(value: progress)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// Thin wrappers over native Button + the built-in .borderedProminent/.bordered
// styles — no custom tint, so the system accent color renders correctly (and
// legibly) in both light and dark mode instead of a hardcoded monochrome tint.
struct PrimaryButton: View {
    let title: String; var icon: String? = nil; let action: () -> Void
    var body: some View { Button(action: action) { Label(title, systemImage: icon ?? "arrow.right").frame(maxWidth: .infinity) }.buttonStyle(.borderedProminent).controlSize(.large) }
}

struct SecondaryButton: View {
    let title: String; let action: () -> Void
    var body: some View { Button(title, action: action).frame(maxWidth: .infinity).buttonStyle(.bordered).controlSize(.large) }
}

#Preview { ContentView() }
