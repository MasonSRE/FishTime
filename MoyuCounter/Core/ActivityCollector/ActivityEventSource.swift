import AppKit
import Foundation

protocol ActivityEventSourcing: AnyObject {
    func start(handler: @escaping (ActivityEvent) -> Void)
    func stop()
}

final class AppKitActivityEventSource: ActivityEventSourcing {
    private var monitors: [Any] = []

    func start(handler: @escaping (ActivityEvent) -> Void) {
        guard monitors.isEmpty else { return }

        let mask: NSEvent.EventTypeMask = [
            .keyDown,
            .leftMouseDown,
            .rightMouseDown,
            .otherMouseDown,
            .mouseMoved,
            .scrollWheel,
            .leftMouseDragged,
            .rightMouseDragged,
            .otherMouseDragged,
        ]

        if let monitor = NSEvent.addGlobalMonitorForEvents(matching: mask, handler: { event in
            guard let activityEvent = Self.map(event: event) else { return }
            handler(activityEvent)
        }) {
            monitors.append(monitor)
        }
    }

    func stop() {
        monitors.forEach { NSEvent.removeMonitor($0) }
        monitors.removeAll()
    }

    private static func map(event: NSEvent) -> ActivityEvent? {
        switch event.type {
        case .keyDown:
            return ActivityEvent(type: .keyboard, timestamp: Date())
        case .leftMouseDown, .rightMouseDown, .otherMouseDown,
             .mouseMoved, .scrollWheel,
             .leftMouseDragged, .rightMouseDragged, .otherMouseDragged:
            return ActivityEvent(type: .mouse, timestamp: Date())
        default:
            return nil
        }
    }
}
