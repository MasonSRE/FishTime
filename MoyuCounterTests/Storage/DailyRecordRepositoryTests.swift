import XCTest
@testable import MoyuCounter

final class DailyRecordRepositoryTests: XCTestCase {
    func test_save_and_fetch_latest_daily_record() throws {
        let repository = try DailyRecordRepository.inMemory()

        try repository.save(.init(
            date: Date(timeIntervalSince1970: 100),
            score: 66,
            moyuScore: 34,
            label: "Balanced Human",
            activeMinutes: 200,
            trackedMinutes: 480,
            highActivityMinutes: 120,
            lowActivityMinutes: 60,
            longestIdleMinutes: 24
        ))
        let latest = try repository.fetchLatest()

        XCTAssertEqual(latest?.score, 66)
        XCTAssertEqual(latest?.moyuScore, 34)
        XCTAssertEqual(latest?.trackedMinutes, 480)
    }

    func test_repository_loads_legacy_daily_record_payload() throws {
        let fileManager = FileManager.default
        let fileURL = fileManager.temporaryDirectory
            .appendingPathComponent("daily-record-legacy-\(UUID().uuidString).json")
        let legacyPayload = """
        [{"date":100,"score":66,"label":"balancedHuman","activeMinutes":200}]
        """
        try legacyPayload.data(using: .utf8)?.write(to: fileURL)

        let repository = try DailyRecordRepository(database: Database(fileURL: fileURL))
        let latest = try repository.fetchLatest()

        XCTAssertEqual(latest?.score, 66)
        XCTAssertEqual(latest?.moyuScore, 34)
        XCTAssertEqual(latest?.trackedMinutes, 200)
        XCTAssertEqual(latest?.highActivityMinutes, 0)
        XCTAssertEqual(latest?.lowActivityMinutes, 0)
        XCTAssertEqual(latest?.longestIdleMinutes, 0)
    }

    func test_fetch_records_returns_only_records_inside_date_interval() throws {
        let repository = try DailyRecordRepository.inMemory()
        try repository.save(DailyRecord(date: makeDate(year: 2026, month: 3, day: 2), score: 10, label: "a", activeMinutes: 10))
        try repository.save(DailyRecord(date: makeDate(year: 2026, month: 3, day: 9), score: 20, label: "b", activeMinutes: 20))
        try repository.save(DailyRecord(date: makeDate(year: 2026, month: 3, day: 10), score: 30, label: "c", activeMinutes: 30))

        let interval = DateInterval(
            start: makeDate(year: 2026, month: 3, day: 9),
            end: makeDate(year: 2026, month: 3, day: 11)
        )
        let records = try repository.fetchRecords(in: interval)

        XCTAssertEqual(records.map(\.score), [20, 30])
    }

    private static let utcCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()

    private func makeDate(year: Int, month: Int, day: Int, hour: Int = 0, minute: Int = 0) -> Date {
        Self.utcCalendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }
}
