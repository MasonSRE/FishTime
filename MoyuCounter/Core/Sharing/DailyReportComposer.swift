import Foundation

final class DailyReportComposer {
    typealias RandomIndexProvider = (_ label: DailyScoreLabel, _ count: Int) -> Int

    private let randomIndexProvider: RandomIndexProvider

    init(randomIndexProvider: @escaping RandomIndexProvider = { _, count in
        Int.random(in: 0..<count)
    }) {
        self.randomIndexProvider = randomIndexProvider
    }

    func makePresentation(from record: DailyRecord) -> DailyReportPresentation {
        let label = DailyScoreLabel(storedValue: record.label)
        let verdictOptions = VerdictCopyLibrary.copies(for: label)
        let index = max(0, min(randomIndexProvider(label, verdictOptions.count), verdictOptions.count - 1))

        let stats = [
            DailyReportStat(label: "活跃分钟", value: "\(record.activeMinutes)"),
            DailyReportStat(label: "最长沉寂", value: "\(record.longestIdleMinutes) 分钟"),
            DailyReportStat(label: "统计范围", value: "\(record.trackedMinutes) 分钟"),
        ]
        let dateText = record.date.formatted(.dateTime.year().month().day())
        let highlight = highlight(for: record)
        let laborScoreText = "劳动分 \(record.score)"
        let moyuScoreText = "摸鱼分 \(record.moyuScore)"

        return DailyReportPresentation(
            label: label,
            title: label.reportTitle,
            laborScoreText: laborScoreText,
            moyuScoreText: moyuScoreText,
            verdict: verdictOptions[index],
            highlight: highlight,
            stats: stats,
            dateText: dateText,
            shareText: shareText(
                title: label.reportTitle,
                laborScoreText: laborScoreText,
                moyuScoreText: moyuScoreText,
                verdict: verdictOptions[index],
                highlight: highlight,
                stats: stats,
                dateText: dateText
            )
        )
    }

    private func highlight(for record: DailyRecord) -> String {
        let trackedMinutes = max(record.trackedMinutes, 1)
        let highActivityRatio = Int((Double(record.highActivityMinutes) / Double(trackedMinutes) * 100).rounded())
        let lowActivityRatio = Int((Double(record.lowActivityMinutes) / Double(trackedMinutes) * 100).rounded())

        if record.longestIdleMinutes >= 60 {
            return "连续 \(record.longestIdleMinutes) 分钟低活跃，堪称隐身办公。"
        }

        if highActivityRatio >= 50 {
            return "全天高活跃占比 \(highActivityRatio)%，工位火花带闪电。"
        }

        if lowActivityRatio >= 50 {
            return "低活跃分钟占比 \(lowActivityRatio)%，鱼群已成规模。"
        }

        if record.score >= 75 {
            return "劳动分 \(record.score)，今天属于工位火力全开。"
        }

        if record.moyuScore >= 75 {
            return "摸鱼分 \(record.moyuScore)，今天属于稳定潜航。"
        }

        return "活跃 \(record.activeMinutes) 分钟，工作与摸鱼保持动态平衡。"
    }

    private func shareText(
        title: String,
        laborScoreText: String,
        moyuScoreText: String,
        verdict: String,
        highlight: String,
        stats: [DailyReportStat],
        dateText: String
    ) -> String {
        let statText = stats
            .map { "\($0.label)：\($0.value)" }
            .joined(separator: " · ")

        return [
            "\(title) | \(laborScoreText) · \(moyuScoreText)",
            verdict,
            highlight,
            statText,
            "\(dateText) · \(AppStrings.App.name)",
        ].joined(separator: "\n")
    }
}

private extension DailyScoreLabel {
    var reportTitle: String {
        switch self {
        case .topNiuMa:
            return AppStrings.Score.topNiuMaTitle
        case .balancedHuman:
            return AppStrings.Score.balancedHumanTitle
        case .moyuMaster:
            return AppStrings.Score.moyuMasterTitle
        }
    }
}
