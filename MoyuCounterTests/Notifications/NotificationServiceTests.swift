import UserNotifications
import XCTest
@testable import MoyuCounter

final class NotificationServiceTests: XCTestCase {
    func test_postDailyResult_marks_notification_for_today_report_destination() {
        let center = StubUserNotificationCenter()
        let service = NotificationService(center: center)

        service.postDailyResult(title: "今日已结算：摸鱼大师", subtitle: "摸鱼分 82")

        let request = try? XCTUnwrap(center.requests.first)
        XCTAssertEqual(
            request?.content.userInfo[NotificationService.destinationUserInfoKey] as? String,
            NotificationService.todayReportDestination
        )
    }

    func test_handle_notification_response_opens_today_report_for_matching_destination() async {
        let center = StubUserNotificationCenter()
        let service = NotificationService(center: center)
        var openCount = 0
        let opened = expectation(description: "open today report")

        service.configure(openTodayReport: {
            openCount += 1
            opened.fulfill()
        })
        service.handleNotificationResponse(userInfo: [
            NotificationService.destinationUserInfoKey: NotificationService.todayReportDestination,
        ])

        await fulfillment(of: [opened], timeout: 1.0)
        XCTAssertEqual(openCount, 1)
    }
}

private final class StubUserNotificationCenter: UserNotificationCentering {
    var delegate: UNUserNotificationCenterDelegate?
    private(set) var requests: [UNNotificationRequest] = []

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        true
    }

    func add(_ request: UNNotificationRequest) {
        requests.append(request)
    }
}
