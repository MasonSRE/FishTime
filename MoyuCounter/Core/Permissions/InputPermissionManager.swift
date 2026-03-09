@preconcurrency import ApplicationServices
import Foundation

enum InputPermissionStatus {
    case notDetermined
    case denied
    case granted
}

protocol InputPermissionManaging {
    func currentStatus() -> InputPermissionStatus
    func requestAccessIfNeeded() -> Bool
}

final class AccessibilityPermissionManager: InputPermissionManaging {
    private enum Keys {
        static let didPrompt = "didPromptAccessibilityPermission"
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func currentStatus() -> InputPermissionStatus {
        if AXIsProcessTrusted() {
            return .granted
        }
        return userDefaults.bool(forKey: Keys.didPrompt) ? .denied : .notDetermined
    }

    func requestAccessIfNeeded() -> Bool {
        if AXIsProcessTrusted() {
            return true
        }

        userDefaults.set(true, forKey: Keys.didPrompt)
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }
}
