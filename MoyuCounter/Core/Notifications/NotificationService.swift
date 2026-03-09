import Foundation
import UserNotifications

protocol UserNotificationCentering: AnyObject {
    var delegate: UNUserNotificationCenterDelegate? { get set }
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
    func add(_ request: UNNotificationRequest)
}

final class SystemUserNotificationCenter: UserNotificationCentering {
    var delegate: UNUserNotificationCenterDelegate? {
        get { UNUserNotificationCenter.current().delegate }
        set { UNUserNotificationCenter.current().delegate = newValue }
    }

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        try await UNUserNotificationCenter.current().requestAuthorization(options: options)
    }

    func add(_ request: UNNotificationRequest) {
        UNUserNotificationCenter.current().add(request)
    }
}

final class NotificationService: NSObject {
    static let destinationUserInfoKey = "destination"
    static let todayReportDestination = "today-report"

    private let center: UserNotificationCentering
    private var openTodayReport: MainThreadActionBox?

    init(center: UserNotificationCentering = SystemUserNotificationCenter()) {
        self.center = center
        super.init()
        center.delegate = self
    }

    func requestPermission() async throws {
        _ = try await center.requestAuthorization(options: [.alert, .sound])
    }

    func configure(openTodayReport: @escaping () -> Void) {
        self.openTodayReport = MainThreadActionBox(action: openTodayReport)
    }

    func postDailyResult(title: String, subtitle: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.subtitle = subtitle
        content.userInfo = [Self.destinationUserInfoKey: Self.todayReportDestination]

        let request = UNNotificationRequest(
            identifier: "daily-result-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        center.add(request)
    }

    func handleNotificationResponse(userInfo: [AnyHashable: Any]) {
        guard userInfo[Self.destinationUserInfoKey] as? String == Self.todayReportDestination else {
            return
        }
        guard let openTodayReport else { return }
        DispatchQueue.main.async {
            openTodayReport.action()
        }
    }
}

extension NotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        handleNotificationResponse(userInfo: response.notification.request.content.userInfo)
    }
}

private final class MainThreadActionBox: @unchecked Sendable {
    let action: () -> Void

    init(action: @escaping () -> Void) {
        self.action = action
    }
}
