import XCTest
@testable import MoyuCounter

@MainActor
final class MenuBarViewModelTests: XCTestCase {
    func test_menu_bar_initial_state_is_idle() {
        let vm = MenuBarViewModel(
            aggregator: MinuteBucketAggregator(),
            tracker: StubTracker(startResult: true),
            scheduler: StubScheduler(shouldRun: false),
            settlementService: StubSettlementService(record: DailyRecord(date: Date(), score: 60, label: "balanced", activeMinutes: 10)),
            posterExporter: StubPosterExporter(),
            now: { Date() }
        )
        XCTAssertEqual(vm.statusText, "未开始")
    }

    func test_check_for_settlement_updates_status_when_scheduler_triggers() {
        let vm = MenuBarViewModel(
            aggregator: MinuteBucketAggregator(),
            tracker: StubTracker(startResult: true),
            scheduler: StubScheduler(shouldRun: true),
            settlementService: StubSettlementService(record: DailyRecord(date: Date(), score: 88, label: "topNiuMa", activeMinutes: 300)),
            posterExporter: StubPosterExporter(),
            now: { Date(timeIntervalSince1970: 1_000) }
        )

        vm.checkForSettlement()

        XCTAssertEqual(vm.statusText, "已结算：88")
    }

    func test_generate_poster_updates_status_when_saved() {
        let vm = MenuBarViewModel(
            aggregator: MinuteBucketAggregator(),
            tracker: StubTracker(startResult: true),
            scheduler: StubScheduler(shouldRun: false),
            settlementService: StubSettlementService(record: DailyRecord(date: Date(), score: 50, label: "balanced", activeMinutes: 60)),
            posterExporter: StubPosterExporter(),
            now: { Date() }
        )

        vm.generatePosterAndSave()

        XCTAssertTrue(vm.statusText.hasPrefix("海报已保存："))
    }
}

private final class StubTracker: ActivityTrackingControlling {
    private let startResult: Bool

    init(startResult: Bool) {
        self.startResult = startResult
    }

    func startTracking() -> Bool {
        startResult
    }

    func stopTracking() {}
}

private final class StubScheduler: DayEndScheduling {
    private let shouldRun: Bool

    init(shouldRun: Bool) {
        self.shouldRun = shouldRun
    }

    func shouldRunSettlement() -> Bool {
        shouldRun
    }

    func nextSettlementDate(from date: Date) -> Date {
        date.addingTimeInterval(60)
    }
}

private final class StubSettlementService: DailySettling {
    let record: DailyRecord

    init(record: DailyRecord) {
        self.record = record
    }

    func settle(for date: Date) throws -> DailyRecord {
        record
    }
}

private final class StubPosterExporter: PosterExporting {
    func generateAndSaveLatestPoster() throws -> URL {
        URL(fileURLWithPath: "/tmp/mock-poster.png")
    }

    func generateAndCopyLatestPoster() throws {}

    func generateAndCopyPoster(for record: DailyRecord) throws {}

    func generateAndSavePeriodPoster(kind: PeriodReportKind, scope: PeriodReportScope) throws -> URL {
        URL(fileURLWithPath: "/tmp/mock-period-poster.png")
    }

    func generateAndCopyPeriodPoster(kind: PeriodReportKind, scope: PeriodReportScope) throws {}
}
