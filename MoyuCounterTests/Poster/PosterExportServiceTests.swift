import Foundation
import XCTest
@testable import MoyuCounter

final class PosterExportServiceTests: XCTestCase {
    func test_generate_and_save_latest_poster_returns_file_url() throws {
        let repository = try DailyRecordRepository.inMemory()
        try repository.save(DailyRecord(date: Date(), score: 66, label: "balancedHuman", activeMinutes: 120))
        let settings = makeSettingsStore(testName: #function)
        settings.selectedReportTemplate = .certificate

        let fileManager = FileManager.default
        let exportDirectory = fileManager.temporaryDirectory
            .appendingPathComponent("moyu-poster-export-tests-\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: exportDirectory, withIntermediateDirectories: true)

        let renderer = StubPosterRenderer(data: Data([0xDE, 0xAD, 0xBE, 0xEF]))
        let clipboard = StubClipboardWriter()

        let service = PosterExportService(
            repository: repository,
            renderer: renderer,
            settingsStore: settings,
            clipboard: clipboard,
            exportDirectory: exportDirectory,
            fileManager: fileManager
        )

        let url = try service.generateAndSaveLatestPoster()

        XCTAssertTrue(fileManager.fileExists(atPath: url.path))
        XCTAssertEqual(try Data(contentsOf: url), Data([0xDE, 0xAD, 0xBE, 0xEF]))
        XCTAssertEqual(renderer.lastPresentation?.templateStyle, .certificate)
    }

    func test_generate_and_copy_latest_poster_writes_clipboard_data() throws {
        let repository = try DailyRecordRepository.inMemory()
        try repository.save(DailyRecord(date: Date(), score: 80, label: "topNiuMa", activeMinutes: 300))
        let settings = makeSettingsStore(testName: #function)
        settings.selectedReportTemplate = .deskLog

        let renderer = StubPosterRenderer(data: Data([0xAA, 0xBB]))
        let clipboard = StubClipboardWriter()

        let service = PosterExportService(
            repository: repository,
            renderer: renderer,
            settingsStore: settings,
            clipboard: clipboard,
            exportDirectory: FileManager.default.temporaryDirectory,
            fileManager: .default
        )

        try service.generateAndCopyLatestPoster()

        XCTAssertEqual(clipboard.writtenData, Data([0xAA, 0xBB]))
        XCTAssertTrue(clipboard.writtenText?.contains("顶级牛马") ?? false)
        XCTAssertTrue(clipboard.writtenText?.contains("劳动分 80") ?? false)
    }

    func test_generate_and_copy_latest_poster_renders_report_presentation() throws {
        let repository = try DailyRecordRepository.inMemory()
        try repository.save(
            DailyRecord(
                date: Date(),
                score: 80,
                moyuScore: 20,
                label: DailyScoreLabel.topNiuMa.rawValue,
                activeMinutes: 300,
                trackedMinutes: 480,
                highActivityMinutes: 280,
                lowActivityMinutes: 40,
                longestIdleMinutes: 12
            )
        )

        let renderer = CapturingPosterRenderer(data: Data([0xAA]))
        let settings = makeSettingsStore(testName: #function)
        settings.selectedReportTemplate = .deskLog
        let service = PosterExportService(
            repository: repository,
            renderer: renderer,
            settingsStore: settings,
            clipboard: StubClipboardWriter(),
            exportDirectory: FileManager.default.temporaryDirectory,
            fileManager: .default
        )

        try service.generateAndCopyLatestPoster()

        XCTAssertEqual(renderer.lastPresentation?.title, "顶级牛马工位日报")
        XCTAssertFalse(renderer.lastPresentation?.highlight.isEmpty ?? true)
        XCTAssertEqual(renderer.lastPresentation?.templateStyle, .deskLog)
    }

    func test_generate_and_copy_period_poster_uses_weekly_snapshot_pipeline() throws {
        let repository = try DailyRecordRepository.inMemory()
        try repository.save(
            DailyRecord(
                date: makeDate(year: 2026, month: 3, day: 9),
                score: 68,
                label: DailyScoreLabel.balancedHuman.rawValue,
                activeMinutes: 120
            )
        )

        let periodRenderer = CapturingPeriodPosterRenderer(data: Data([0xAA]))
        let clipboard = StubClipboardWriter()
        let service = PosterExportService(
            repository: repository,
            renderer: StubPosterRenderer(data: Data([0x01])),
            periodRenderer: periodRenderer,
            settingsStore: makeSettingsStore(testName: #function),
            composer: DailyReportComposer(randomIndexProvider: { _, _ in 0 }),
            periodAggregator: PeriodReportAggregator(
                repository: repository,
                calendar: Self.utcCalendar,
                now: { self.makeDate(year: 2026, month: 3, day: 10, hour: 12, minute: 0) }
            ),
            periodComposer: PeriodReportComposer(calendar: Self.utcCalendar),
            clipboard: clipboard,
            exportDirectory: FileManager.default.temporaryDirectory,
            fileManager: .default
        )

        try service.generateAndCopyPeriodPoster(kind: .weekly, scope: .current)

        XCTAssertEqual(periodRenderer.lastPresentation?.kind, .weekly)
        XCTAssertEqual(clipboard.writtenData, Data([0xAA]))
    }

    private static let utcCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.firstWeekday = 2
        calendar.minimumDaysInFirstWeek = 4
        return calendar
    }()

    private func makeSettingsStore(testName: String) -> SettingsStore {
        let defaults = UserDefaults(suiteName: testName)!
        defaults.removePersistentDomain(forName: testName)
        return SettingsStore(userDefaults: defaults)
    }

    private func makeDate(year: Int, month: Int, day: Int, hour: Int = 0, minute: Int = 0) -> Date {
        Self.utcCalendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }
}

private final class StubPosterRenderer: PosterRendering {
    let data: Data
    private(set) var lastPresentation: DailyReportPresentation?

    init(data: Data) {
        self.data = data
    }

    func render(report: DailyReportPresentation) throws -> Data {
        lastPresentation = report
        return data
    }
}

private final class CapturingPosterRenderer: PosterRendering {
    let data: Data
    private(set) var lastPresentation: DailyReportPresentation?

    init(data: Data) {
        self.data = data
    }

    func render(report: DailyReportPresentation) throws -> Data {
        lastPresentation = report
        return data
    }
}

private final class CapturingPeriodPosterRenderer: PeriodPosterRendering {
    let data: Data
    private(set) var lastPresentation: PeriodReportPresentation?

    init(data: Data) {
        self.data = data
    }

    func render(report: PeriodReportPresentation) throws -> Data {
        lastPresentation = report
        return data
    }
}

private final class StubClipboardWriter: ClipboardWriting {
    private(set) var writtenData: Data?
    private(set) var writtenText: String?

    func writeSharePayload(imageData: Data, text: String) {
        writtenData = imageData
        writtenText = text
    }
}
