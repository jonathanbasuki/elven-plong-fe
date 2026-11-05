import SwiftUI
import UIKit

public enum ZoneDelegationStatus: Equatable, Sendable {
    case none
    case ongoing
    case done
}

/// Native UIKit-backed zoomable scroll view providing 120Hz ProMotion fluid pinch-to-zoom,
/// natural deceleration, rubber-band bouncing, and double-tap zoom around touch coordinates.
public struct ZoomableScrollView<Content: View>: UIViewRepresentable {
    private var content: Content
    @Binding private var currentZoom: CGFloat
    private var onDoubleTap: (() -> Void)?
    
    public init(
        currentZoom: Binding<CGFloat>,
        @ViewBuilder content: () -> Content
    ) {
        self._currentZoom = currentZoom
        self.content = content()
    }
    
    public func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 4.0
        scrollView.bouncesZoom = true
        scrollView.bounces = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.clipsToBounds = true
        scrollView.backgroundColor = .clear
        
        // Host the SwiftUI content
        let hostedView = context.coordinator.hostingController.view!
        hostedView.translatesAutoresizingMaskIntoConstraints = false
        hostedView.backgroundColor = .clear
        scrollView.addSubview(hostedView)
        
        NSLayoutConstraint.activate([
            hostedView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            hostedView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            hostedView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            hostedView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            hostedView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            hostedView.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor)
        ])
        
        // Double-tap gesture for native zoom toggle
        let doubleTap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)
        
        context.coordinator.scrollView = scrollView
        return scrollView
    }
    
    public func updateUIView(_ uiView: UIScrollView, context: Context) {
        context.coordinator.hostingController.rootView = content
        
        // Update zoom externally if changed via HUD buttons
        if abs(uiView.zoomScale - currentZoom) > 0.05 {
            uiView.setZoomScale(currentZoom, animated: true)
        }
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public class Coordinator: NSObject, UIScrollViewDelegate {
        var parent: ZoomableScrollView
        var hostingController: UIHostingController<Content>
        weak var scrollView: UIScrollView?
        
        init(_ parent: ZoomableScrollView) {
            self.parent = parent
            self.hostingController = UIHostingController(rootView: parent.content)
            super.init()
        }
        
        public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return hostingController.view
        }
        
        public func scrollViewDidZoom(_ scrollView: UIScrollView) {
            DispatchQueue.main.async {
                self.parent.currentZoom = scrollView.zoomScale
            }
        }
        
        @objc func handleDoubleTap(_ recognizer: UITapGestureRecognizer) {
            guard let scrollView = scrollView else { return }
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            
            if scrollView.zoomScale > 1.2 {
                scrollView.setZoomScale(1.0, animated: true)
            } else {
                let point = recognizer.location(in: hostingController.view)
                let targetScale: CGFloat = 2.2
                let width = scrollView.bounds.width / targetScale
                let height = scrollView.bounds.height / targetScale
                let targetRect = CGRect(x: point.x - width / 2, y: point.y - height / 2, width: width, height: height)
                scrollView.zoom(to: targetRect, animated: true)
            }
        }
    }
}

/// Interactive Floor Plan Container hosting ZoomableScrollView and on-screen HUD zoom controls.
public struct NativeZoomableFloorPlan: View {
    public let pantryZone: VenueZone?
    public let collabZone: VenueZone?
    public let meetingZone: VenueZone?
    public var delegationStatus: ZoneDelegationStatus = .none
    public let onSelectZone: (VenueZone) -> Void
    
    @State private var zoomScale: CGFloat = 1.0
    
    public init(
        pantryZone: VenueZone?,
        collabZone: VenueZone?,
        meetingZone: VenueZone?,
        delegationStatus: ZoneDelegationStatus = .none,
        onSelectZone: @escaping (VenueZone) -> Void
    ) {
        self.pantryZone = pantryZone
        self.collabZone = collabZone
        self.meetingZone = meetingZone
        self.delegationStatus = delegationStatus
        self.onSelectZone = onSelectZone
    }
    
    public var body: some View {
        ZStack {
            // Background Container
            RoundedRectangle(cornerRadius: 22.3, style: .continuous)
                .fill(Color(uiColor: .systemGray6))
            
            // Native ProMotion Zoomable ScrollView with fluid pinch-to-zoom
            ZoomableScrollView(currentZoom: $zoomScale) {
                GeometryReader { geo in
                    let width = geo.size.width
                    let height = geo.size.height
                    
                    ZStack {
                        // Denah Floor Plan Image
                        Image("denah")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: width * 0.92, height: height * 0.92)
                            .position(x: width / 2, y: height / 2)
                        
                        // Zone Overlays with stationary markers
                        zonesOverlay(width: width * 0.92, height: height * 0.92, centerX: width / 2, centerY: height / 2)
                    }
                    .frame(width: width, height: height)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 22.3, style: .continuous))
        }
        .frame(minHeight: 520, maxHeight: 640)
        .clipShape(RoundedRectangle(cornerRadius: 22.3, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22.3, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }
    
    // MARK: - Zones Overlay
    @ViewBuilder
    private func zonesOverlay(width: CGFloat, height: CGFloat, centerX: CGFloat, centerY: CGFloat) -> some View {
        ZStack {
            // Zone 2: Collab Area (Top Region, crowd 20)
            if let collab = collabZone {
                Button {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    onSelectZone(collab)
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.black.opacity(0.18))
                            .stroke(Color.black.opacity(0.35), lineWidth: 1)
                        
                        VStack(spacing: 4) {
                            sensorMarker
                            
                            Text("\(collab.currentCount)")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                                .shadow(color: .black.opacity(0.5), radius: 2)
                        }
                    }
                }
                .buttonStyle(.plain)
                .frame(width: width * 0.55, height: height * 0.22)
                .position(x: centerX, y: centerY - height * 0.24)
                .accessibilityLabel("Zone \(collab.name), \(collab.currentCount) people")
            }
            
            // Zone 1: Pantry Academy (Center Region)
            if let pantry = pantryZone {
                let pantryCount = delegationStatus == .done ? 15 : pantry.currentCount
                
                Button {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    onSelectZone(pantry)
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(pantryColor)
                            .stroke(Color.black.opacity(0.6), lineWidth: 1.2)
                        
                        VStack(spacing: 4) {
                            sensorMarker
                            
                            Text("\(pantryCount)")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.white)
                                .shadow(color: .black.opacity(0.6), radius: 3)
                        }
                    }
                }
                .buttonStyle(.plain)
                .frame(width: width * 0.52, height: height * 0.17)
                .position(x: centerX - width * 0.02, y: centerY + height * 0.02)
                .accessibilityLabel("Zone \(pantry.name), \(pantryCount) people")
            }
            
            // Zone 3: Meeting & Pods (Bottom Region, crowd 10)
            if let meeting = meetingZone {
                Button {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    onSelectZone(meeting)
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.black.opacity(0.18))
                            .stroke(Color.black.opacity(0.35), lineWidth: 1)
                        
                        VStack(spacing: 4) {
                            sensorMarker
                            
                            Text("\(meeting.currentCount)")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                                .shadow(color: .black.opacity(0.5), radius: 2)
                        }
                    }
                }
                .buttonStyle(.plain)
                .frame(width: width * 0.48, height: height * 0.18)
                .position(x: centerX - width * 0.04, y: centerY + height * 0.24)
                .accessibilityLabel("Zone \(meeting.name), \(meeting.currentCount) people")
            }
        }
    }
    
    // MARK: - Stationary Sensor Marker (Crisp & Stable matching Figma)
    private var sensorMarker: some View {
        ZStack {
            Circle()
                .fill(Color.black)
                .frame(width: 26, height: 26)
                .shadow(color: Color.black.opacity(0.3), radius: 3, y: 1)
            
            Circle()
                .stroke(Color(red: 0.35, green: 0.65, blue: 1.0), lineWidth: 2)
                .frame(width: 26, height: 26)
            
            Image(systemName: "video.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white)
        }
    }
    
    private var pantryColor: Color {
        switch delegationStatus {
        case .none:
            // Overflow Red
            return Color(red: 0.65, green: 0.05, blue: 0.05).opacity(0.55)
        case .ongoing:
            // Light Blue tint matching sample/Manager/overview ongoing.svg
            return Color(red: 0.42, green: 0.64, blue: 0.91).opacity(0.65)
        case .done:
            // Normal gray tint matching sample/Manager/overview done.svg
            return Color.black.opacity(0.18)
        }
    }
}

