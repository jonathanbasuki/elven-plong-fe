import SwiftUI

/// Interactive Floor Plan View supporting pinch-to-zoom (1.0x to 4.0x),
/// panning when zoomed in, double-tap to zoom, and on-screen HUD zoom controls.
/// Fully conforms to Apple HIG for gestures, haptics, and responsive layout.
public struct InteractiveFloorPlanView: View {
    public let pantryZone: VenueZone?
    public let collabZone: VenueZone?
    public let meetingZone: VenueZone?
    public let onSelectZone: (VenueZone) -> Void
    
    // Zoom & Pan state
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    private let minScale: CGFloat = 1.0
    private let maxScale: CGFloat = 4.0
    
    public init(
        pantryZone: VenueZone?,
        collabZone: VenueZone?,
        meetingZone: VenueZone?,
        onSelectZone: @escaping (VenueZone) -> Void
    ) {
        self.pantryZone = pantryZone
        self.collabZone = collabZone
        self.meetingZone = meetingZone
        self.onSelectZone = onSelectZone
    }
    
    public var body: some View {
        ZStack {
            // Background Container
            RoundedRectangle(cornerRadius: 22.3, style: .continuous)
                .fill(Color(uiColor: .systemGray6))
            
            // Zoomable and Pannable Floor Plan Canvas
            GeometryReader { containerGeo in
                let containerWidth = containerGeo.size.width
                let containerHeight = containerGeo.size.height
                
                // Keep the denah fitted nicely with padding
                let planWidth = containerWidth * 0.92
                let planHeight = containerHeight * 0.92
                
                ZStack {
                    // Floor Plan Image
                    Image("denah")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: planWidth, height: planHeight)
                    
                    // Zone Overlays positioned synchronously with the denah image
                    zonesOverlay(width: planWidth, height: planHeight)
                }
                .frame(width: planWidth, height: planHeight)
                .scaleEffect(scale)
                .offset(offset)
                .position(x: containerWidth / 2, y: containerHeight / 2)
                .gesture(zoomGesture)
                .simultaneousGesture(panGesture(containerSize: containerGeo.size))
                .onTapGesture(count: 2) {
                    handleDoubleTap()
                }
            }
            .clipped()
            
            // Floating HUD Controls (Top Trailing)
            VStack {
                HStack {
                    Spacer()
                    zoomControlsHUD
                        .padding(12)
                }
                Spacer()
            }
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
    private func zonesOverlay(width: CGFloat, height: CGFloat) -> some View {
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
                        
                        Text("\(collab.currentCount)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.5), radius: 2)
                    }
                }
                .buttonStyle(.plain)
                .frame(width: width * 0.55, height: height * 0.22)
                .position(x: width * 0.50, y: height * 0.26)
                .accessibilityLabel("Zone \(collab.name), \(collab.currentCount) people")
            }
            
            // Zone 1: Pantry Academy (Center Region, crowd 50 - Overflowed)
            if let pantry = pantryZone {
                ZStack {
                    Button {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        onSelectZone(pantry)
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(red: 0.65, green: 0.05, blue: 0.05).opacity(0.55))
                                .stroke(Color.black.opacity(0.6), lineWidth: 1.2)
                            
                            VStack(spacing: 2) {
                                Spacer()
                                Text("\(pantry.currentCount)")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundStyle(.white)
                                    .shadow(color: .black.opacity(0.6), radius: 3)
                                    .padding(.bottom, 6)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .frame(width: width * 0.52, height: height * 0.17)
                    .position(x: width * 0.48, y: height * 0.52)
                    .accessibilityLabel("Zone \(pantry.name), \(pantry.currentCount) people, Overflow")
                    
                    // Interactive Crowd Detection Pin
                    CrowdPinView(count: pantry.currentCount) {
                        onSelectZone(pantry)
                    }
                    .position(x: width * 0.48, y: height * 0.44)
                }
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
                        
                        Text("\(meeting.currentCount)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.5), radius: 2)
                    }
                }
                .buttonStyle(.plain)
                .frame(width: width * 0.48, height: height * 0.18)
                .position(x: width * 0.46, y: height * 0.74)
                .accessibilityLabel("Zone \(meeting.name), \(meeting.currentCount) people")
            }
        }
    }
    
    // MARK: - Zoom HUD Controls
    private var zoomControlsHUD: some View {
        HStack(spacing: 6) {
            // Zoom indicator badge
            Text(String(format: "%.1fx", scale))
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(Color(uiColor: .label))
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(Color(uiColor: .systemBackground).opacity(0.85))
                .clipShape(Capsule())
            
            // Zoom In Button
            Button {
                zoomIn()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color(uiColor: .label))
                    .frame(width: 32, height: 32)
                    .background(Color(uiColor: .systemBackground).opacity(0.85))
                    .clipShape(Circle())
            }
            .disabled(scale >= maxScale)
            .accessibilityLabel("Zoom in floor plan")
            
            // Zoom Out Button
            Button {
                zoomOut()
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color(uiColor: .label))
                    .frame(width: 32, height: 32)
                    .background(Color(uiColor: .systemBackground).opacity(0.85))
                    .clipShape(Circle())
            }
            .disabled(scale <= minScale)
            .accessibilityLabel("Zoom out floor plan")
            
            // Reset Button (if zoomed)
            if scale > 1.05 {
                Button {
                    resetZoom()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color(uiColor: .label))
                        .frame(width: 32, height: 32)
                        .background(Color(uiColor: .systemBackground).opacity(0.85))
                        .clipShape(Circle())
                }
                .accessibilityLabel("Reset floor plan zoom")
            }
        }
        .padding(4)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(Color.primary.opacity(0.12), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.08), radius: 6, y: 2)
    }
    
    // MARK: - Gestures
    private var zoomGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let newScale = lastScale * value
                scale = min(max(newScale, minScale), maxScale)
            }
            .onEnded { _ in
                lastScale = scale
                if scale <= 1.05 {
                    resetZoom()
                }
            }
    }
    
    private func panGesture(containerSize: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                guard scale > 1.05 else { return }
                let maxOffsetX = (containerSize.width * (scale - 1)) / 2
                let maxOffsetY = (containerSize.height * (scale - 1)) / 2
                
                let proposedX = lastOffset.width + value.translation.width
                let proposedY = lastOffset.height + value.translation.height
                
                offset = CGSize(
                    width: min(max(proposedX, -maxOffsetX), maxOffsetX),
                    height: min(max(proposedY, -maxOffsetY), maxOffsetY)
                )
            }
            .onEnded { _ in
                lastOffset = offset
            }
    }
    
    // MARK: - Actions
    private func zoomIn() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            scale = min(scale + 0.5, maxScale)
            lastScale = scale
        }
    }
    
    private func zoomOut() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            scale = max(scale - 0.5, minScale)
            lastScale = scale
            if scale <= 1.05 {
                offset = .zero
                lastOffset = .zero
            }
        }
    }
    
    private func resetZoom() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            scale = 1.0
            lastScale = 1.0
            offset = .zero
            lastOffset = .zero
        }
    }
    
    private func handleDoubleTap() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            if scale > 1.2 {
                scale = 1.0
                lastScale = 1.0
                offset = .zero
                lastOffset = .zero
            } else {
                scale = 2.2
                lastScale = 2.2
            }
        }
    }
}

#Preview {
    InteractiveFloorPlanView(
        pantryZone: VenueZone(id: "z1", name: "Pantry Academy", currentCount: 50, warningThreshold: 20, crowdedThreshold: 35),
        collabZone: VenueZone(id: "z2", name: "Collab Area", currentCount: 20, warningThreshold: 15, crowdedThreshold: 30),
        meetingZone: VenueZone(id: "z3", name: "Meeting & Pods", currentCount: 10, warningThreshold: 10, crowdedThreshold: 25),
        onSelectZone: { _ in }
    )
}

