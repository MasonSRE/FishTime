import Foundation

struct DailyReportStat: Equatable {
    let label: String
    let value: String
}

struct DailyReportPresentation: Equatable {
    let label: DailyScoreLabel
    let title: String
    let laborScoreText: String
    let moyuScoreText: String
    let verdict: String
    let highlight: String
    let stats: [DailyReportStat]
    let dateText: String
    let shareText: String
}
