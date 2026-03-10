import Foundation

final class PeriodReportComposer {
    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        var normalizedCalendar = calendar
        normalizedCalendar.firstWeekday = 2
        normalizedCalendar.minimumDaysInFirstWeek = 4
        self.calendar = normalizedCalendar
    }

    func makePresentation(from snapshot: PeriodReportSnapshot) -> PeriodReportPresentation {
        let recordCount = snapshot.records.count
        let averageScore = recordCount == 0 ? 0 : Int((Double(snapshot.records.map(\.score).reduce(0, +)) / Double(recordCount)).rounded())
        let totalActiveMinutes = snapshot.records.map(\.activeMinutes).reduce(0, +)
        let maxIdleMinutes = snapshot.records.map(\.longestIdleMinutes).max() ?? 0

        let stats = [
            DailyReportStat(label: AppStrings.Report.periodRecordedDays, value: "\(recordCount)"),
            DailyReportStat(label: AppStrings.Report.periodAverageScore, value: "\(averageScore)"),
            DailyReportStat(label: AppStrings.Report.periodTotalActiveMinutes, value: "\(totalActiveMinutes)"),
            DailyReportStat(label: AppStrings.Report.periodMaxIdleMinutes, value: "\(maxIdleMinutes)"),
        ]

        let highlights = makeHighlights(from: snapshot.records)
        let title = title(for: snapshot)
        let subtitle = subtitle(for: snapshot)
        let verdict = verdict(for: snapshot.kind, averageScore: averageScore)
        let footer = "\(rangeText(for: snapshot.interval)) · \(AppStrings.App.name)"

        return PeriodReportPresentation(
            kind: snapshot.kind,
            title: title,
            subtitle: subtitle,
            verdict: verdict,
            stats: stats,
            highlights: highlights,
            footer: footer,
            shareText: ([title, subtitle, verdict] + stats.map { "\($0.label)：\($0.value)" } + highlights + [footer])
                .joined(separator: "\n")
        )
    }

    private func title(for snapshot: PeriodReportSnapshot) -> String {
        switch (snapshot.kind, snapshot.scope) {
        case (.weekly, .current):
            return AppStrings.Report.weeklyMemorialTitle
        case (.monthly, .current):
            return AppStrings.Report.monthlyMemorialTitle
        case (.weekly, .previousCompleted):
            return "\(rangeText(for: snapshot.interval))周报"
        case (.monthly, .previousCompleted):
            return snapshot.interval.start.formatted(.dateTime.year().month()) + "月报"
        }
    }

    private func subtitle(for snapshot: PeriodReportSnapshot) -> String {
        if snapshot.isInProgress {
            return "截至" + snapshot.interval.end.formatted(.dateTime.year().month().day())
        }

        return rangeText(for: snapshot.interval)
    }

    private func verdict(for kind: PeriodReportKind, averageScore: Int) -> String {
        let periodName = kind == .weekly ? "本周" : "本月"

        switch averageScore {
        case 70...:
            return "\(periodName)属于\(AppStrings.Report.periodVerdictHigh)"
        case 40...:
            return "\(periodName)属于\(AppStrings.Report.periodVerdictBalanced)"
        default:
            return "\(periodName)属于\(AppStrings.Report.periodVerdictLow)"
        }
    }

    private func makeHighlights(from records: [DailyRecord]) -> [String] {
        guard !records.isEmpty else {
            return [AppStrings.Report.periodEmptySubtitle]
        }

        let topWorkDay = records.max(by: compareWorkDay)
        let topMoyuDay = records.max(by: compareMoyuDay)

        return [
            "最拼一天：\(dayText(for: topWorkDay?.date)), 劳动分 \(topWorkDay?.score ?? 0)",
            "最会摸一天：\(dayText(for: topMoyuDay?.date)), 摸鱼分 \(topMoyuDay?.moyuScore ?? 0)",
        ]
    }

    private func compareWorkDay(lhs: DailyRecord, rhs: DailyRecord) -> Bool {
        if lhs.score == rhs.score {
            return lhs.date < rhs.date
        }

        return lhs.score < rhs.score
    }

    private func compareMoyuDay(lhs: DailyRecord, rhs: DailyRecord) -> Bool {
        if lhs.moyuScore == rhs.moyuScore {
            return lhs.date < rhs.date
        }

        return lhs.moyuScore < rhs.moyuScore
    }

    private func dayText(for date: Date?) -> String {
        guard let date else { return "--" }

        return date.formatted(.dateTime.month().day())
    }

    private func rangeText(for interval: DateInterval) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "MM.dd"
        let displayEnd = interval.end.addingTimeInterval(-1)
        return "\(formatter.string(from: interval.start)) - \(formatter.string(from: displayEnd))"
    }
}
