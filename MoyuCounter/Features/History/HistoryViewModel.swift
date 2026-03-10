import Combine
import Foundation

struct HistoryRecordRow: Equatable {
    let date: Date
    let scoreText: String
    let presentationTitle: String
    let verdict: String
}

final class HistoryViewModel: ObservableObject {
    @Published private(set) var records: [HistoryRecordRow] = []

    private let repository: DailyRecordRepository
    private let composer: DailyReportComposer
    private let posterExporter: PosterExporting?
    private var sourceRecords: [Date: DailyRecord] = [:]

    init(
        repository: DailyRecordRepository,
        composer: DailyReportComposer = DailyReportComposer(),
        posterExporter: PosterExporting? = nil
    ) {
        self.repository = repository
        self.composer = composer
        self.posterExporter = posterExporter
        reload()
    }

    func reload() {
        let storedRecords = (try? repository.fetchRecent(limit: 30)) ?? []
        sourceRecords = Dictionary(uniqueKeysWithValues: storedRecords.map { ($0.date, $0) })
        records = storedRecords.map { record in
            let presentation = composer.makePresentation(from: record)
            return HistoryRecordRow(
                date: record.date,
                scoreText: "劳动分 \(record.score)",
                presentationTitle: presentation.title,
                verdict: presentation.verdict
            )
        }
    }

    func resetData() {
        try? repository.reset()
        records = []
        sourceRecords = [:]
    }

    func copyReport(for row: HistoryRecordRow) {
        guard let record = sourceRecords[row.date] else { return }
        try? posterExporter?.generateAndCopyPoster(for: record)
    }

    func copyPreviousWeeklyReport() {
        try? posterExporter?.generateAndCopyPeriodPoster(kind: .weekly, scope: .previousCompleted)
    }

    func copyPreviousMonthlyReport() {
        try? posterExporter?.generateAndCopyPeriodPoster(kind: .monthly, scope: .previousCompleted)
    }
}
