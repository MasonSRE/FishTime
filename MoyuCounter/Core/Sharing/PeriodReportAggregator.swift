import Foundation

struct PeriodReportSnapshot: Equatable {
    let kind: PeriodReportKind
    let scope: PeriodReportScope
    let interval: DateInterval
    let records: [DailyRecord]
    let isInProgress: Bool
}

final class PeriodReportAggregator {
    private let repository: DailyRecordRepository
    private let calendar: Calendar
    private let now: () -> Date

    init(
        repository: DailyRecordRepository,
        calendar: Calendar = .current,
        now: @escaping () -> Date = Date.init
    ) {
        self.repository = repository
        self.now = now

        var normalizedCalendar = calendar
        normalizedCalendar.firstWeekday = 2
        normalizedCalendar.minimumDaysInFirstWeek = 4
        self.calendar = normalizedCalendar
    }

    func makeSnapshot(kind: PeriodReportKind, scope: PeriodReportScope) throws -> PeriodReportSnapshot {
        let current = now()
        let interval = interval(for: kind, scope: scope, current: current)
        let records = try repository.fetchRecords(in: interval)

        return PeriodReportSnapshot(
            kind: kind,
            scope: scope,
            interval: interval,
            records: records,
            isInProgress: scope == .current
        )
    }

    private func interval(for kind: PeriodReportKind, scope: PeriodReportScope, current: Date) -> DateInterval {
        switch (kind, scope) {
        case (.weekly, .current):
            let week = calendar.dateInterval(of: .weekOfYear, for: current)!
            return DateInterval(start: week.start, end: current)
        case (.weekly, .previousCompleted):
            let currentWeek = calendar.dateInterval(of: .weekOfYear, for: current)!
            let previousStart = calendar.date(byAdding: .day, value: -7, to: currentWeek.start)!
            return DateInterval(start: previousStart, end: currentWeek.start)
        case (.monthly, .current):
            let month = calendar.dateInterval(of: .month, for: current)!
            return DateInterval(start: month.start, end: current)
        case (.monthly, .previousCompleted):
            let currentMonth = calendar.dateInterval(of: .month, for: current)!
            let previousMonthReference = calendar.date(byAdding: .day, value: -1, to: currentMonth.start)!
            let previousMonth = calendar.dateInterval(of: .month, for: previousMonthReference)!
            return DateInterval(start: previousMonth.start, end: currentMonth.start)
        }
    }
}
