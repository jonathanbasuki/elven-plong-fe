import Foundation

public protocol ClockProtocol: Sendable {
    var now: Date { get }
    func sleep(seconds: TimeInterval) async throws
}

public struct SystemClock: ClockProtocol {
    public init() {}
    
    public var now: Date {
        Date()
    }
    
    public func sleep(seconds: TimeInterval) async throws {
        let nanoseconds = UInt64(max(0, seconds) * 1_000_000_000)
        try await Task.sleep(nanoseconds: nanoseconds)
    }
}

public final class ControllableClock: ClockProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private var _now: Date
    private var sleepYieldHandler: (@Sendable (TimeInterval) async throws -> Void)?
    
    public init(initialDate: Date = Date()) {
        self._now = initialDate
    }
    
    public var now: Date {
        lock.lock()
        defer { lock.unlock() }
        return _now
    }
    
    public func advance(by seconds: TimeInterval) {
        lock.lock()
        _now = _now.addingTimeInterval(seconds)
        lock.unlock()
    }
    
    public func setSleepHandler(_ handler: @escaping @Sendable (TimeInterval) async throws -> Void) {
        lock.lock()
        sleepYieldHandler = handler
        lock.unlock()
    }
    
    public func sleep(seconds: TimeInterval) async throws {
        var handler: (@Sendable (TimeInterval) async throws -> Void)?
        lock.lock()
        _now = _now.addingTimeInterval(seconds)
        handler = sleepYieldHandler
        lock.unlock()
        
        if let handler = handler {
            try await handler(seconds)
        } else {
            // Instant sleep in test mode - yields thread to allow scheduled tasks to execute
            await Task.yield()
        }
    }
}
