import XCTest
@testable import MoyuCounter

final class PeriodReportAggregatorTests: XCTestCase {
    func test_aggregator_returns_current_week_snapshot_with_progress_state() throws {
        let repository = try DailyRecordRepository.inMemory()
        try repository.save(
            DailyRecord(
                date: makeDate(year: 2026, month: 3, day: 9),
                score: 65,
                label: DailyScoreLabel.balancedHuman.rawValue,
                activeMinutes: 120
            )
        )
        try repository.save(
            DailyRecord(
                date: makeDate(year: 2026, month: 3, day: 10),
                score: 72,
                label: DailyScoreLabel.topNiuMa.rawValue,
                activeMinutes: 180
            )
        )

        let aggregator = PeriodReportAggregator(
            repository: repository,
            calendar: Self.utcCalendar,
            now: { self.makeDate(year: 2026, month: 3, day: 10, hour: 20, minute: 0) }
        )

        let snapshot = try aggregator.makeSnapshot(kind: .weekly, scope: .current)

        XCTAssertEqual(snapshot.kind, .weekly)
        XCTAssertEqual(snapshot.scope, .current)
        XCTAssertTrue(snapshot.isInProgress)
        XCTAssertEqual(snapshot.records.count, 2)
        XCTAssertEqual(snapshot.interval.start, makeDate(year: 2026, month: 3, day: 9))
        XCTAssertEqual(snapshot.interval.end, makeDate(year: 2026, month: 3, day: 10, hour: 20, minute: 0))
    }

    func test_aggregator_returns_previous_month_snapshot() throws {
        let repository = try DailyRecordRepository.inMemory()
        try repository.save(
            DailyRecord(
                date: makeDate(year: 2026, month: 2, day: 10),
                score: 44,
                label: DailyScoreLabel.balancedHuman.rawValue,
                activeMinutes: 90
            )
        )
        try repository.save(
            DailyRecord(
                date: makeDate(year: 2026, month: 3, day: 5),
                score: 88,
                label: DailyScoreLabel.topNiuMa.rawValue,
                activeMinutes: 240
            )
        )

        let aggregator = PeriodReportAggregator(
            repository: repository,
            calendar: Self.utcCalendar,
            now: { self.makeDate(year: 2026, month: 3, day: 10, hour: 20, minute: 0) }
        )

        let snapshot = try aggregator.makeSnapshot(kind: .monthly, scope: .previousCompleted)

        XCTAssertEqual(snapshot.kind, .monthly)
        XCTAssertEqual(snapshot.scope, .previousCompleted)
        XCTAssertFalse(snapshot.isInProgress)
        XCTAssertEqual(snapshot.records.map(\.score), [44])
        XCTAssertEqual(snapshot.interval.start, makeDate(year: 2026, month: 2, day: 1))
        XCTAssertEqual(snapshot.interval.end, makeDate(year: 2026, month: 3, day: 1))
    }

    private static let utcCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.firstWeekday = 2
        calendar.minimumDaysInFirstWeek = 4
        return calendar
    }()

    private func makeDate(year: Int, month: Int, day: Int, hour: Int = 0, minute: Int = 0) -> Date {
        Self.utcCalendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }
}
