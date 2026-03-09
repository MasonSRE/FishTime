import XCTest
@testable import MoyuCounter

final class SettingsTrackingWindowProviderTests: XCTestCase {
    func test_whole_day_scope_returns_full_day_epoch_range() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        let settings = SettingsStore(userDefaults: defaults)
        settings.scope = .wholeDay

        let provider = SettingsTrackingWindowProvider(settingsStore: settings, calendar: Self.utcCalendar)
        let date = makeDate(year: 2026, month: 3, day: 2, hour: 15, minute: 0)
        let dayStartMinute = Int(Self.utcCalendar.startOfDay(for: date).timeIntervalSince1970) / 60

        let range = provider.epochMinuteRange(for: date)
        XCTAssertEqual(range.count, 1440)
        XCTAssertEqual(range.lowerBound, dayStartMinute)
        XCTAssertEqual(range.upperBound, dayStartMinute + 1_439)
    }

    func test_work_hours_scope_supports_cross_day_shift() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        let settings = SettingsStore(userDefaults: defaults)
        settings.scope = .workHoursOnly
        settings.workStartMinutes = 22 * 60
        settings.workEndMinutes = 6 * 60

        let provider = SettingsTrackingWindowProvider(settingsStore: settings, calendar: Self.utcCalendar)
        let date = makeDate(year: 2026, month: 3, day: 2, hour: 23, minute: 0)
        let dayStartMinute = Int(Self.utcCalendar.startOfDay(for: date).timeIntervalSince1970) / 60

        let range = provider.epochMinuteRange(for: date)
        XCTAssertEqual(range.lowerBound, dayStartMinute + 1_320)
        XCTAssertEqual(range.upperBound, dayStartMinute + 1_799)
        XCTAssertEqual(range.count, 480)
    }

    private static let utcCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()

    private func makeDate(year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Date {
        Self.utcCalendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }
}
