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

    @Published var selectedReportSurface: ReportSurface {
        didSet {
            userDefaults.set(selectedReportSurface.rawValue, forKey: Keys.selectedReportSurface)
        }
    }

    @Published var selectedPeriodScope: PeriodReportScope {
        didSet {
            userDefaults.set(selectedPeriodScope.rawValue, forKey: Keys.selectedPeriodScope)
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

        if let rawSurface = userDefaults.string(forKey: Keys.selectedReportSurface),
           let savedSurface = ReportSurface(rawValue: rawSurface) {
            self.selectedReportSurface = savedSurface
        } else {
            self.selectedReportSurface = .daily
        }

        if let rawPeriodScope = userDefaults.string(forKey: Keys.selectedPeriodScope),
           let savedPeriodScope = PeriodReportScope(rawValue: rawPeriodScope) {
            self.selectedPeriodScope = savedPeriodScope
        } else {
            self.selectedPeriodScope = .current
        }
    }
}

private enum Keys {
    static let scope = "trackingScope"
    static let workStartMinutes = "workStartMinutes"
    static let workEndMinutes = "workEndMinutes"
    static let selectedReportTemplate = "selectedReportTemplate"
    static let selectedReportSurface = "selectedReportSurface"
    static let selectedPeriodScope = "selectedPeriodScope"
}
