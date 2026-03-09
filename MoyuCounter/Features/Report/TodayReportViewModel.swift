import Combine
import Foundation

@MainActor
final class TodayReportViewModel: ObservableObject {
    @Published private(set) var presentation: DailyReportPresentation?

    private let repository: DailyRecordRepository
    private let composer: DailyReportComposer

    init(
        repository: DailyRecordRepository,
        composer: DailyReportComposer = DailyReportComposer()
    ) {
        self.repository = repository
        self.composer = composer
        reload()
    }

    func reload() {
        guard let latest = try? repository.fetchLatest() else {
            presentation = nil
            return
        }

        presentation = composer.makePresentation(from: latest)
    }

    func refreshVerdict() {
        reload()
    }
}
