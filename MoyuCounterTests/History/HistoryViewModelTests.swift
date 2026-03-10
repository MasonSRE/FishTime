import XCTest
@testable import MoyuCounter

final class HistoryViewModelTests: XCTestCase {
    func test_history_returns_max_30_days() throws {
        let repository = try DailyRecordRepository.inMemory()
        for day in 1...40 {
            try repository.save(
                DailyRecord(
                    date: Date(timeIntervalSince1970: TimeInterval(day * 86_400)),
                    score: day,
                    label: "sample",
                    activeMinutes: 100
                )
            )
        }

        let viewModel = HistoryViewModel(
            repository: repository,
            composer: DailyReportComposer(randomIndexProvider: { _, _ in 0 })
        )

        XCTAssertEqual(viewModel.records.count, 30)
        XCTAssertEqual(viewModel.records.first?.scoreText, "劳动分 40")
        XCTAssertEqual(viewModel.records.last?.scoreText, "劳动分 11")
    }

    func test_history_exposes_latest_presentations_for_re_share() throws {
        let repository = try DailyRecordRepository.inMemory()
        try repository.save(
            DailyRecord(
                date: Date(timeIntervalSince1970: 86_400),
                score: 18,
                moyuScore: 82,
                label: DailyScoreLabel.moyuMaster.rawValue,
                activeMinutes: 20,
                trackedMinutes: 480,
                highActivityMinutes: 0,
                lowActivityMinutes: 320,
                longestIdleMinutes: 120
            )
        )

        let viewModel = HistoryViewModel(
            repository: repository,
            composer: DailyReportComposer(randomIndexProvider: { _, _ in 0 })
        )

        viewModel.reload()

        XCTAssertEqual(viewModel.records.first?.presentationTitle, "摸鱼大师")
        XCTAssertFalse(viewModel.records.first?.verdict.isEmpty ?? true)
    }

    func test_copy_report_for_row_uses_poster_exporter_with_selected_record() throws {
        let repository = try DailyRecordRepository.inMemory()
        try repository.save(
            DailyRecord(
                date: Date(timeIntervalSince1970: 86_400),
                score: 55,
                moyuScore: 45,
                label: DailyScoreLabel.balancedHuman.rawValue,
                activeMinutes: 180,
                trackedMinutes: 480,
                highActivityMinutes: 120,
                lowActivityMinutes: 120,
                longestIdleMinutes: 18
            )
        )
        let settings = makeSettingsStore(testName: #function)
        settings.selectedReportTemplate = .certificate
        let renderer = CapturingPosterRenderer(data: Data([0xAB]))
        let exporter = PosterExportService(
            repository: repository,
            renderer: renderer,
            settingsStore: settings,
            clipboard: StubClipboardWriter(),
            exportDirectory: FileManager.default.temporaryDirectory,
            fileManager: .default
        )
        let viewModel = HistoryViewModel(
            repository: repository,
            composer: DailyReportComposer(randomIndexProvider: { _, _ in 0 }),
            posterExporter: exporter
        )

        let row = try XCTUnwrap(viewModel.records.first)
        viewModel.copyReport(for: row)

        XCTAssertEqual(renderer.lastPresentation?.templateStyle, .certificate)
        XCTAssertEqual(renderer.lastPresentation?.title, "平衡人类奖状")
    }

    func test_copy_previous_week_period_report_uses_period_exporter() throws {
        let repository = try DailyRecordRepository.inMemory()
        try repository.save(
            DailyRecord(
                date: Date(timeIntervalSince1970: 86_400),
                score: 70,
                label: DailyScoreLabel.topNiuMa.rawValue,
                activeMinutes: 180
            )
        )

        let exporter = StubPeriodPosterExporter()
        let viewModel = HistoryViewModel(
            repository: repository,
            composer: DailyReportComposer(randomIndexProvider: { _, _ in 0 }),
            posterExporter: exporter
        )

        viewModel.copyPreviousWeeklyReport()

        XCTAssertEqual(exporter.lastCopiedPeriodKind, .weekly)
        XCTAssertEqual(exporter.lastCopiedPeriodScope, .previousCompleted)
    }

    func test_copy_previous_month_period_report_uses_period_exporter() throws {
        let repository = try DailyRecordRepository.inMemory()
        try repository.save(
            DailyRecord(
                date: Date(timeIntervalSince1970: 86_400),
                score: 22,
                label: DailyScoreLabel.moyuMaster.rawValue,
                activeMinutes: 50
            )
        )

        let exporter = StubPeriodPosterExporter()
        let viewModel = HistoryViewModel(
            repository: repository,
            composer: DailyReportComposer(randomIndexProvider: { _, _ in 0 }),
            posterExporter: exporter
        )

        viewModel.copyPreviousMonthlyReport()

        XCTAssertEqual(exporter.lastCopiedPeriodKind, .monthly)
        XCTAssertEqual(exporter.lastCopiedPeriodScope, .previousCompleted)
    }

    private func makeSettingsStore(testName: String) -> SettingsStore {
        let defaults = UserDefaults(suiteName: testName)!
        defaults.removePersistentDomain(forName: testName)
        return SettingsStore(userDefaults: defaults)
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

private final class StubClipboardWriter: ClipboardWriting {
    func writeSharePayload(imageData: Data, text: String) {}
}

private final class StubPeriodPosterExporter: PosterExporting {
    private(set) var lastCopiedPeriodKind: PeriodReportKind?
    private(set) var lastCopiedPeriodScope: PeriodReportScope?

    func generateAndSaveLatestPoster() throws -> URL {
        URL(fileURLWithPath: "/tmp/mock-latest-poster.png")
    }

    func generateAndCopyLatestPoster() throws {}

    func generateAndCopyPoster(for record: DailyRecord) throws {}

    func generateAndSavePeriodPoster(kind: PeriodReportKind, scope: PeriodReportScope) throws -> URL {
        URL(fileURLWithPath: "/tmp/mock-period-poster.png")
    }

    func generateAndCopyPeriodPoster(kind: PeriodReportKind, scope: PeriodReportScope) throws {
        lastCopiedPeriodKind = kind
        lastCopiedPeriodScope = scope
    }
}
