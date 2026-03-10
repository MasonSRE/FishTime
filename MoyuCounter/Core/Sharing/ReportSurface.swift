import Foundation

enum ReportSurface: String, CaseIterable, Hashable {
    case daily
    case weekly
    case monthly

    var displayName: String {
        switch self {
        case .daily:
            return AppStrings.Report.dailySurface
        case .weekly:
            return AppStrings.Report.weeklySurface
        case .monthly:
            return AppStrings.Report.monthlySurface
        }
    }

    var iconName: String {
        switch self {
        case .daily:
            return "sun.max.fill"
        case .weekly:
            return "calendar"
        case .monthly:
            return "calendar.badge.clock"
        }
    }
}
