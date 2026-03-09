import XCTest
@testable import MoyuCounter

final class DayEndSchedulerTests: XCTestCase {
    func test_scheduler_triggers_settlement_once_per_day() {
        var now = makeDate(year: 2026, month: 3, day: 2, hour: 23, minute: 59)
        let scheduler = DayEndScheduler(now: { now }, calendar: Self.calendar)

        XCTAssertTrue(scheduler.shouldRunSettlement())
        XCTAssertFalse(scheduler.shouldRunSettlement())

        now = makeDate(year: 2026, month: 3, day: 3, hour: 23, minute: 59)
        XCTAssertTrue(scheduler.shouldRunSettlement())
    }

    func test_next_settlement_date_uses_same_day_when_before_cutoff() {
        let now = makeDate(year: 2026, month: 3, day: 2, hour: 10, minute: 0)
        let scheduler = DayEndScheduler(now: { now }, calendar: Self.calendar)

        let next = scheduler.nextSettlementDate(from: now)

        XCTAssertEqual(next, makeDate(year: 2026, month: 3, day: 2, hour: 23, minute: 59))
    }

    func test_next_settlement_date_rolls_to_next_day_after_cutoff() {
        let now = makeDate(year: 2026, month: 3, day: 2, hour: 23, minute: 59)
        let scheduler = DayEndScheduler(now: { now }, calendar: Self.calendar)

        let next = scheduler.nextSettlementDate(from: now.addingTimeInterval(90))

        XCTAssertEqual(next, makeDate(year: 2026, month: 3, day: 3, hour: 23, minute: 59))
    }

    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()

    private func makeDate(year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Date {
        Self.calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }
}
