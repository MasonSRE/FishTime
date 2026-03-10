import Foundation

struct PeriodReportPresentation: Equatable {
    let kind: PeriodReportKind
    let title: String
    let subtitle: String
    let verdict: String
    let stats: [DailyReportStat]
    let highlights: [String]
    let footer: String
    let shareText: String
}
