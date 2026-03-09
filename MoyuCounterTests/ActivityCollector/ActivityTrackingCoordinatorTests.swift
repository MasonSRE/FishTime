import XCTest
@testable import MoyuCounter

final class ActivityTrackingCoordinatorTests: XCTestCase {
    func test_start_tracking_requests_permission_when_not_determined_and_starts_on_grant() {
        let permissionManager = StubPermissionManager(status: .notDetermined, requestResult: true)
        let eventSource = StubEventSource()
        let collector = RecordingActivityHandler()
        let coordinator = ActivityTrackingCoordinator(
            permissionManager: permissionManager,
            eventSource: eventSource,
            collector: collector
        )

        XCTAssertTrue(coordinator.startTracking())
        XCTAssertEqual(permissionManager.requestCount, 1)
        XCTAssertTrue(eventSource.isStarted)

        eventSource.emit(.init(type: .keyboard, timestamp: Date(timeIntervalSince1970: 1)))
        XCTAssertEqual(collector.handledEvents.count, 1)
    }

    func test_start_tracking_fails_when_permission_denied() {
        let permissionManager = StubPermissionManager(status: .denied, requestResult: false)
        let eventSource = StubEventSource()
        let collector = RecordingActivityHandler()
        let coordinator = ActivityTrackingCoordinator(
            permissionManager: permissionManager,
            eventSource: eventSource,
            collector: collector
        )

        XCTAssertFalse(coordinator.startTracking())
        XCTAssertFalse(eventSource.isStarted)
        XCTAssertFalse(coordinator.isTracking)
    }

    func test_stop_tracking_stops_event_source() {
        let permissionManager = StubPermissionManager(status: .granted, requestResult: true)
        let eventSource = StubEventSource()
        let collector = RecordingActivityHandler()
        let coordinator = ActivityTrackingCoordinator(
            permissionManager: permissionManager,
            eventSource: eventSource,
            collector: collector
        )

        XCTAssertTrue(coordinator.startTracking())
        coordinator.stopTracking()

        XCTAssertFalse(eventSource.isStarted)
        XCTAssertFalse(coordinator.isTracking)
    }
}

private final class StubPermissionManager: InputPermissionManaging {
    var status: InputPermissionStatus
    var requestResult: Bool
    private(set) var requestCount = 0

    init(status: InputPermissionStatus, requestResult: Bool) {
        self.status = status
        self.requestResult = requestResult
    }

    func currentStatus() -> InputPermissionStatus {
        status
    }

    func requestAccessIfNeeded() -> Bool {
        requestCount += 1
        status = requestResult ? .granted : .denied
        return requestResult
    }
}

private final class StubEventSource: ActivityEventSourcing {
    private(set) var isStarted = false
    private var handler: ((ActivityEvent) -> Void)?

    func start(handler: @escaping (ActivityEvent) -> Void) {
        isStarted = true
        self.handler = handler
    }

    func stop() {
        isStarted = false
        handler = nil
    }

    func emit(_ event: ActivityEvent) {
        handler?(event)
    }
}

private final class RecordingActivityHandler: ActivityHandling {
    private(set) var handledEvents: [ActivityEvent] = []

    func handle(_ event: ActivityEvent) {
        handledEvents.append(event)
    }
}
