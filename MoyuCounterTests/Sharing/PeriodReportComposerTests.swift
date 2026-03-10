import XCTest
@testable import MoyuCounter

final class PeriodReportComposerTests: XCTestCase {
    func test_composer_builds_monthly_presentation_with_key_stats_and_highlights() {
        let snapshot = PeriodReportSnapshot(
            kind: .monthly,
            scope: .current,
            interval: DateInterval(
                start: makeDate(year: 2026, month: 3, day: 1),
                end: makeDate(year: 2026, month: 3, day: 10, hour: 20, minute: 0)
            ),
            records: [
                DailyRecord(
                    date: makeDate(year: 2026, month: 3, day: 3),
                    score: 82,
                    moyuScore: 18,
                    label: DailyScoreLabel.topNiuMa.rawValue,
                    activeMinutes: 300,
                    trackedMinutes: 480,
                    highActivityMinutes: 240,
                    lowActivityMinutes: 40,
                    longestIdleMinutes: 15
                ),
                DailyRecord(
                    date: makeDate(year: 2026, month: 3, day: 6),
                    score: 25,
                    moyuScore: 75,
                    label: DailyScoreLabel.moyuMaster.rawValue,
                    activeMinutes: 40,
                    trackedMinutes: 480,
                    highActivityMinutes: 10,
                    lowActivityMinutes: 320,
                    longestIdleMinutes: 120
                ),
            ],
            isInProgress: true
        )

        let presentation = PeriodReportComposer(calendar: Self.utcCalendar).makePresentation(from: snapshot)

        XCTAssertEqual(presentation.title, "本月摸鱼纪念卡")
        XCTAssertEqual(presentation.stats.count, 4)
        XCTAssertTrue(presentation.subtitle.contains("截至"))
        XCTAssertTrue(presentation.highlights.contains(where: { $0.contains("最拼一天") }))
        XCTAssertTrue(presentation.highlights.contains(where: { $0.contains("最会摸一天") }))
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
