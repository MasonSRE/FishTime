import Foundation

enum PeriodReportScope: String, CaseIterable, Hashable {
    case current
    case previousCompleted

    var displayName: String {
        switch self {
        case .current:
            return AppStrings.Report.currentPeriodScope
        case .previousCompleted:
            return AppStrings.Report.previousPeriodScope
        }
    }
}
