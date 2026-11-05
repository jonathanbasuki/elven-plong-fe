import Foundation
import MultipeerConnectivity
import Observation
import UIKit

/// Apple MultipeerConnectivity implementation for zero-server two-device demo.
/// Operates peer-to-peer over local Wi-Fi and Bluetooth without requiring an external server or IP setup.
@Observable
@MainActor
public final class MultipeerTaskSyncService: NSObject, TaskSyncServiceProtocol {
    public static let shared = MultipeerTaskSyncService()
    
    // Bonjour service type registered in Info.plist (max 15 chars, lowercase ASCII/hyphens)
    private static let serviceType = "plong-sync"
    
    public private(set) var connectionState: SyncConnectionState = .disconnected
    public private(set) var currentRole: UserRole = .manager
    public private(set) var connectedPeers: [MCPeerID] = []
    
    public var isConnected: Bool {
        !connectedPeers.isEmpty
    }
    
    // Callbacks
    public var onTaskDispatched: ((TaskLogItem) -> Void)?
    public var onTaskCompleted: ((UUID, String, Int, Int) -> Void)?
    public var onConnectionChanged: ((SyncConnectionState) -> Void)?
    
    // Multipeer connectivity internals
    private var peerID: MCPeerID?
    private var session: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    
    public override init() {
        super.init()
    }
    
    // MARK: - Lifecycle
    
    public func start(as role: UserRole) {
        stop()
        self.currentRole = role
        
        let deviceName = UIDevice.current.name
        let sanitizedName = "\(role.rawValue) (\(deviceName))"
        let newPeerID = MCPeerID(displayName: sanitizedName)
        self.peerID = newPeerID
        
        let newSession = MCSession(peer: newPeerID, securityIdentity: nil, encryptionPreference: .none)
        newSession.delegate = self
        self.session = newSession
        
        let discoveryInfo: [String: String] = ["role": role.rawValue]
        
        let newAdvertiser = MCNearbyServiceAdvertiser(
            peer: newPeerID,
            discoveryInfo: discoveryInfo,
            serviceType: Self.serviceType
        )
        newAdvertiser.delegate = self
        self.advertiser = newAdvertiser
        newAdvertiser.startAdvertisingPeer()
        
        let newBrowser = MCNearbyServiceBrowser(
            peer: newPeerID,
            serviceType: Self.serviceType
        )
        newBrowser.delegate = self
        self.browser = newBrowser
        newBrowser.startBrowsingForPeers()
        
        self.connectionState = .searching
        self.onConnectionChanged?(.searching)
    }
    
    public func stop() {
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
        
        browser?.stopBrowsingForPeers()
        browser = nil
        
        session?.disconnect()
        session = nil
        
        peerID = nil
        connectedPeers.removeAll()
        
        connectionState = .disconnected
        onConnectionChanged?(.disconnected)
    }
    
    // MARK: - Broadcasting
    
    public func broadcastTaskDispatched(_ task: TaskLogItem) {
        guard let session = session, !session.connectedPeers.isEmpty else {
            return
        }
        
        let message = SyncMessage(
            action: .taskDispatched,
            task: task,
            taskId: task.id,
            zoneId: task.zoneID,
            senderRole: currentRole,
            senderDeviceName: UIDevice.current.name
        )
        
        sendSyncMessage(message)
    }
    
    public func broadcastTaskCompleted(taskId: UUID, zoneId: String, zoneCount: Int, totalCrowd: Int) {
        guard let session = session, !session.connectedPeers.isEmpty else {
            return
        }
        
        let message = SyncMessage(
            action: .taskCompleted,
            taskId: taskId,
            zoneId: zoneId,
            zoneCount: zoneCount,
            totalCrowd: totalCrowd,
            senderRole: currentRole,
            senderDeviceName: UIDevice.current.name
        )
        
        sendSyncMessage(message)
    }
    
    private func sendSyncMessage(_ message: SyncMessage) {
        guard let session = session, !session.connectedPeers.isEmpty else { return }
        
        do {
            let data = try JSONEncoder().encode(message)
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
        } catch {
            // Error handling
        }
    }
}

// MARK: - MCSessionDelegate
extension MultipeerTaskSyncService: MCSessionDelegate {
    public func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        Task { @MainActor in
            switch state {
            case .connected:
                if !self.connectedPeers.contains(peerID) {
                    self.connectedPeers.append(peerID)
                }
                let newState: SyncConnectionState = .connected(peerName: peerID.displayName)
                self.connectionState = newState
                self.onConnectionChanged?(newState)
                
            case .connecting:
                self.connectionState = .searching
                self.onConnectionChanged?(.searching)
                
            case .notConnected:
                self.connectedPeers.removeAll { $0 == peerID }
                if let next = self.connectedPeers.first {
                    let newState: SyncConnectionState = .connected(peerName: next.displayName)
                    self.connectionState = newState
                    self.onConnectionChanged?(newState)
                } else {
                    let newState: SyncConnectionState = .searching
                    self.connectionState = newState
                    self.onConnectionChanged?(newState)
                }
                
            @unknown default:
                break
            }
        }
    }
    
    public func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        Task { @MainActor in
            do {
                let message = try JSONDecoder().decode(SyncMessage.self, from: data)
                switch message.action {
                case .taskDispatched:
                    if let task = message.task {
                        self.onTaskDispatched?(task)
                    }
                    
                case .taskCompleted:
                    if let taskId = message.taskId {
                        self.onTaskCompleted?(
                            taskId,
                            message.zoneId ?? MockDataConstants.zone1Id,
                            message.zoneCount ?? 15,
                            message.totalCrowd ?? 45
                        )
                    }
                    
                case .syncState:
                    break
                }
            } catch {
                // Ignore malformed packets
            }
        }
    }
    
    public func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    public func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    public func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension MultipeerTaskSyncService: MCNearbyServiceAdvertiserDelegate {
    public func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didReceiveInvitationFromPeer peerID: MCPeerID,
        withContext context: Data?,
        invitationHandler: @escaping (Bool, MCSession?) -> Void
    ) {
        Task { @MainActor in
            // Auto-accept invitation from peer
            guard let session = self.session else {
                invitationHandler(false, nil)
                return
            }
            invitationHandler(true, session)
        }
    }
}

// MARK: - MCNearbyServiceBrowserDelegate
extension MultipeerTaskSyncService: MCNearbyServiceBrowserDelegate {
    public func browser(
        _ browser: MCNearbyServiceBrowser,
        foundPeer peerID: MCPeerID,
        withDiscoveryInfo info: [String: String]?
    ) {
        Task { @MainActor in
            guard let session = self.session else { return }
            
            // Only invite complementary role or peers not yet connected
            let peerRole = info?["role"]
            if peerRole != self.currentRole.rawValue {
                browser.invitePeer(peerID, to: session, withContext: nil, timeout: 30)
            }
        }
    }
    
    public func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        // Handled via MCSessionDelegate
    }
}

