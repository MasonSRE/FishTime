import Foundation

struct DailyReportStat: Equatable {
    let label: String
    let value: String
}

struct DailyReportPresentation: Equatable {
    let label: DailyScoreLabel
    let templateStyle: ReportTemplateStyle
    let title: String
    let laborScoreText: String
    let moyuScoreText: String
    let verdict: String
    let highlight: String
    let stats: [DailyReportStat]
    let dateText: String
    let shareText: String

    init(
        label: DailyScoreLabel,
        templateStyle: ReportTemplateStyle = .standard,
        title: String,
        laborScoreText: String,
        moyuScoreText: String,
        verdict: String,
        highlight: String,
        stats: [DailyReportStat],
        dateText: String,
        shareText: String
    ) {
        self.label = label
        self.templateStyle = templateStyle
        self.title = title
        self.laborScoreText = laborScoreText
        self.moyuScoreText = moyuScoreText
        self.verdict = verdict
        self.highlight = highlight
        self.stats = stats
        self.dateText = dateText
        self.shareText = shareText
    }
}
