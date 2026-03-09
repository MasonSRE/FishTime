import XCTest
@testable import MoyuCounter

final class PermissionOnboardingViewModelTests: XCTestCase {
    func test_initial_message_reflects_denied_status() {
        let permissionManager = StubPermissionManager(status: .denied, requestResult: false)
        let viewModel = PermissionOnboardingViewModel(permissionManager: permissionManager)

        XCTAssertEqual(viewModel.message, "权限被拒绝，请在系统设置中开启辅助功能权限。")
        XCTAssertFalse(viewModel.canStartTracking)
    }

    func test_request_permission_updates_to_ready_when_granted() {
        let permissionManager = StubPermissionManager(status: .notDetermined, requestResult: true)
        let viewModel = PermissionOnboardingViewModel(permissionManager: permissionManager)

        viewModel.requestPermission()

        XCTAssertEqual(viewModel.message, "权限已授权，可开始统计。")
        XCTAssertTrue(viewModel.canStartTracking)
    }
}

private final class StubPermissionManager: InputPermissionManaging {
    var status: InputPermissionStatus
    var requestResult: Bool

    init(status: InputPermissionStatus, requestResult: Bool) {
        self.status = status
        self.requestResult = requestResult
    }

    func currentStatus() -> InputPermissionStatus {
        status
    }

    func requestAccessIfNeeded() -> Bool {
        status = requestResult ? .granted : .denied
        return requestResult
    }
}
