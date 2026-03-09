import Foundation

protocol ActivityTrackingControlling: AnyObject {
    @discardableResult
    func startTracking() -> Bool
    func stopTracking()
}

final class ActivityTrackingCoordinator: ActivityTrackingControlling {
    private let permissionManager: InputPermissionManaging
    private let eventSource: ActivityEventSourcing
    private let collector: ActivityHandling

    private(set) var isTracking = false

    init(permissionManager: InputPermissionManaging, eventSource: ActivityEventSourcing, collector: ActivityHandling) {
        self.permissionManager = permissionManager
        self.eventSource = eventSource
        self.collector = collector
    }

    @discardableResult
    func startTracking() -> Bool {
        let status = permissionManager.currentStatus()
        let isGranted: Bool

        switch status {
        case .granted:
            isGranted = true
        case .notDetermined:
            isGranted = permissionManager.requestAccessIfNeeded()
        case .denied:
            isGranted = false
        }

        guard isGranted else {
            isTracking = false
            return false
        }

        guard !isTracking else {
            return true
        }

        eventSource.start { [weak self] event in
            self?.collector.handle(event)
        }
        isTracking = true
        return true
    }

    func stopTracking() {
        guard isTracking else { return }
        eventSource.stop()
        isTracking = false
    }
}
