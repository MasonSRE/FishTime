import Foundation

protocol DayEndScheduling: AnyObject {
    func shouldRunSettlement() -> Bool
    func nextSettlementDate(from date: Date) -> Date
}

final class DayEndScheduler: DayEndScheduling {
    private let now: () -> Date
    private let calendar: Calendar
    private var lastSettlementDay: DateComponents?

    init(now: @escaping () -> Date = Date.init, calendar: Calendar = .current) {
        self.now = now
        self.calendar = calendar
    }

    func shouldRunSettlement() -> Bool {
        let current = now()
        let day = calendar.dateComponents([.year, .month, .day], from: current)
        let time = calendar.dateComponents([.hour, .minute], from: current)

        guard (time.hour ?? 0) > 23 || ((time.hour ?? 0) == 23 && (time.minute ?? 0) >= 59) else {
            return false
        }

        if lastSettlementDay == day {
            return false
        }

        lastSettlementDay = day
        return true
    }

    func nextSettlementDate(from date: Date) -> Date {
        let startOfDay = calendar.startOfDay(for: date)
        let todayTarget = calendar.date(byAdding: DateComponents(hour: 23, minute: 59), to: startOfDay) ?? date
        if date < todayTarget {
            return todayTarget
        }

        let nextDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
        return calendar.date(byAdding: DateComponents(hour: 23, minute: 59), to: nextDay) ?? todayTarget
    }
}
