import XCTest
@testable import MoyuCounter

@MainActor
final class TodayReportViewModelTests: XCTestCase {
    func test_today_report_view_model_loads_latest_report_summary() throws {
        let repository = try DailyRecordRepository.inMemory()
        try repository.save(
            DailyRecord(
                date: Date(),
                score: 66,
                moyuScore: 34,
                label: DailyScoreLabel.balancedHuman.rawValue,
                activeMinutes: 150,
                trackedMinutes: 480,
                highActivityMinutes: 120,
                lowActivityMinutes: 100,
                longestIdleMinutes: 24
            )
        )
        let settings = makeSettingsStore(testName: #function)

        let viewModel = TodayReportViewModel(
            repository: repository,
            settingsStore: settings,
            composer: DailyReportComposer(randomIndexProvider: { _, _ in 0 })
        )

        viewModel.reload()

        XCTAssertEqual(viewModel.presentation?.title, "平衡人类")
        XCTAssertEqual(viewModel.presentation?.templateStyle, .standard)
    }

    func test_today_report_view_model_uses_saved_template_on_load() throws {
        let repository = try DailyRecordRepository.inMemory()
        try repository.save(
            DailyRecord(
                date: Date(),
                score: 66,
                moyuScore: 34,
                label: DailyScoreLabel.balancedHuman.rawValue,
                activeMinutes: 150,
                trackedMinutes: 480,
                highActivityMinutes: 120,
                lowActivityMinutes: 100,
                longestIdleMinutes: 24
            )
        )
        let settings = makeSettingsStore(testName: #function)
        settings.selectedReportTemplate = .deskLog

        let viewModel = TodayReportViewModel(
            repository: repository,
            settingsStore: settings,
            composer: DailyReportComposer(randomIndexProvider: { _, _ in 0 })
        )

        XCTAssertEqual(viewModel.presentation?.templateStyle, .deskLog)
    }

    func test_select_template_updates_presentation_and_persists_selection() throws {
        let repository = try DailyRecordRepository.inMemory()
        try repository.save(
            DailyRecord(
                date: Date(),
                score: 66,
                moyuScore: 34,
                label: DailyScoreLabel.balancedHuman.rawValue,
                activeMinutes: 150,
                trackedMinutes: 480,
                highActivityMinutes: 120,
                lowActivityMinutes: 100,
                longestIdleMinutes: 24
            )
        )
        let settings = makeSettingsStore(testName: #function)

        let viewModel = TodayReportViewModel(
            repository: repository,
            settingsStore: settings,
            composer: DailyReportComposer(randomIndexProvider: { _, _ in 0 })
        )

        viewModel.selectTemplate(.certificate)

        XCTAssertEqual(viewModel.presentation?.templateStyle, .certificate)
        XCTAssertEqual(settings.selectedReportTemplate, .certificate)
    }

    func test_refresh_verdict_rebuilds_presentation_without_changing_score_text() throws {
        let repository = try DailyRecordRepository.inMemory()
        try repository.save(
            DailyRecord(
                date: Date(),
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
        let settings = makeSettingsStore(testName: #function)
        settings.selectedReportTemplate = .deskLog

        var indexes = [0, 1].makeIterator()
        let viewModel = TodayReportViewModel(
            repository: repository,
            settingsStore: settings,
            composer: DailyReportComposer(randomIndexProvider: { _, _ in indexes.next() ?? 1 })
        )
        let original = try XCTUnwrap(viewModel.presentation)

        viewModel.refreshVerdict()

        XCTAssertNotEqual(viewModel.presentation?.verdict, original.verdict)
        XCTAssertEqual(viewModel.presentation?.laborScoreText, original.laborScoreText)
        XCTAssertEqual(viewModel.presentation?.highlight, original.highlight)
        XCTAssertEqual(viewModel.presentation?.templateStyle, .deskLog)
    }

    private func makeSettingsStore(testName: String) -> SettingsStore {
        let defaults = UserDefaults(suiteName: testName)!
        defaults.removePersistentDomain(forName: testName)
        return SettingsStore(userDefaults: defaults)
    }
}
