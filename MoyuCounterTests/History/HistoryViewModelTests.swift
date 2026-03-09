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
        let exporter = CapturingPosterExporter()
        let viewModel = HistoryViewModel(
            repository: repository,
            composer: DailyReportComposer(randomIndexProvider: { _, _ in 0 }),
            posterExporter: exporter
        )

        let row = try XCTUnwrap(viewModel.records.first)
        viewModel.copyReport(for: row)

        XCTAssertEqual(exporter.copiedScores, [55])
    }
}

private final class CapturingPosterExporter: PosterExporting {
    private(set) var copiedScores: [Int] = []

    func generateAndSaveLatestPoster() throws -> URL {
        URL(fileURLWithPath: "/tmp/mock-poster.png")
    }

    func generateAndCopyLatestPoster() throws {}

    func generateAndCopyPoster(for record: DailyRecord) throws {
        copiedScores.append(record.score)
    }
}
