import Combine

final class PermissionOnboardingViewModel: ObservableObject {
    @Published private(set) var message: String = ""
    @Published private(set) var canStartTracking: Bool = false

    private let permissionManager: InputPermissionManaging

    init(permissionManager: InputPermissionManaging) {
        self.permissionManager = permissionManager
        refreshStatus(afterRequest: false)
    }

    func requestPermission() {
        _ = permissionManager.requestAccessIfNeeded()
        refreshStatus(afterRequest: true)
    }

    func refreshStatus(afterRequest: Bool = false) {
        switch permissionManager.currentStatus() {
        case .granted:
            message = AppStrings.Permission.granted
            canStartTracking = true
        case .notDetermined:
            message = AppStrings.Permission.required
            canStartTracking = false
        case .denied:
            message = afterRequest
                ? AppStrings.Permission.requested
                : AppStrings.Permission.denied
            canStartTracking = false
        }
    }
}
