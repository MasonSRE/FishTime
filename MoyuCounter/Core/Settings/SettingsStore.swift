import Combine
import Foundation

final class SettingsStore: ObservableObject {
    @Published var scope: TrackingScope {
        didSet {
            userDefaults.set(scope.rawValue, forKey: Keys.scope)
        }
    }

    @Published var workStartMinutes: Int {
        didSet {
            userDefaults.set(workStartMinutes, forKey: Keys.workStartMinutes)
        }
    }

    @Published var workEndMinutes: Int {
        didSet {
            userDefaults.set(workEndMinutes, forKey: Keys.workEndMinutes)
        }
    }

    @Published var selectedReportTemplate: ReportTemplateStyle {
        didSet {
            userDefaults.set(selectedReportTemplate.rawValue, forKey: Keys.selectedReportTemplate)
        }
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        if let rawScope = userDefaults.string(forKey: Keys.scope),
           let savedScope = TrackingScope(rawValue: rawScope) {
            self.scope = savedScope
        } else {
            self.scope = .workHoursOnly
        }

        let defaultStart = 9 * 60
        let defaultEnd = 18 * 60
        self.workStartMinutes = userDefaults.object(forKey: Keys.workStartMinutes) as? Int ?? defaultStart
        self.workEndMinutes = userDefaults.object(forKey: Keys.workEndMinutes) as? Int ?? defaultEnd

        if let rawTemplate = userDefaults.string(forKey: Keys.selectedReportTemplate),
           let savedTemplate = ReportTemplateStyle(rawValue: rawTemplate) {
            self.selectedReportTemplate = savedTemplate
        } else {
            self.selectedReportTemplate = .standard
        }
    }
}

private enum Keys {
    static let scope = "trackingScope"
    static let workStartMinutes = "workStartMinutes"
    static let workEndMinutes = "workEndMinutes"
    static let selectedReportTemplate = "selectedReportTemplate"
}
