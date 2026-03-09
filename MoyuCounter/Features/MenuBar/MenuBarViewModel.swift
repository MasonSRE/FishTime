import Combine
import Foundation

@MainActor
final class MenuBarViewModel: ObservableObject {
    @Published var statusText: String = AppStrings.RuntimeStatus.notStarted
    @Published var todayEventCount: Int = 0

    private let aggregator: MinuteBucketAggregator
    private let tracker: ActivityTrackingControlling
    private let scheduler: DayEndScheduling
    private let settlementService: DailySettling?
    private let posterExporter: PosterExporting?
    private let now: () -> Date
    private var activityRefreshCancellable: AnyCancellable?
    private var settlementTimer: Timer?

    init(
        aggregator: MinuteBucketAggregator = MinuteBucketAggregator(),
        tracker: ActivityTrackingControlling? = nil,
        scheduler: DayEndScheduling? = nil,
        settlementService: DailySettling? = nil,
        posterExporter: PosterExporting? = nil,
        now: @escaping () -> Date = Date.init
    ) {
        self.aggregator = aggregator
        self.scheduler = scheduler ?? DayEndScheduler()
        self.now = now

        if let tracker {
            self.tracker = tracker
        } else {
            let collector = ActivityCollector(aggregator: aggregator)
            self.tracker = ActivityTrackingCoordinator(
                permissionManager: AccessibilityPermissionManager(),
                eventSource: AppKitActivityEventSource(),
                collector: collector
            )
        }

        if let settlementService {
            self.settlementService = settlementService
        } else {
            self.settlementService = Self.makeLiveSettlementService(aggregator: aggregator)
        }

        if let posterExporter {
            self.posterExporter = posterExporter
        } else {
            self.posterExporter = Self.makeLivePosterExporter()
        }
    }

    func refreshStatus(hasStartedTracking: Bool) {
        statusText = hasStartedTracking ? AppStrings.RuntimeStatus.tracking : AppStrings.RuntimeStatus.notStarted
    }

    func updateTodayEventCount(_ count: Int) {
        todayEventCount = count
    }

    func startTracking() {
        let started = tracker.startTracking()
        refreshStatus(hasStartedTracking: started)
        guard started else { return }

        todayEventCount = aggregator.totalCount()
        activityRefreshCancellable?.cancel()
        activityRefreshCancellable = Timer.publish(every: 10, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.todayEventCount = self?.aggregator.totalCount() ?? 0
            }

        checkForSettlement()
        scheduleNextSettlementCheck()
    }

    func stopTracking() {
        tracker.stopTracking()
        activityRefreshCancellable?.cancel()
        activityRefreshCancellable = nil
        settlementTimer?.invalidate()
        settlementTimer = nil
        refreshStatus(hasStartedTracking: false)
    }

    func checkForSettlement() {
        guard scheduler.shouldRunSettlement(), let settlementService else { return }
        do {
            let record = try settlementService.settle(for: now())
            statusText = "\(AppStrings.RuntimeStatus.settledPrefix)：\(record.score)"
        } catch {
            statusText = AppStrings.RuntimeStatus.settlementFailed
        }
    }

    private func scheduleNextSettlementCheck() {
        settlementTimer?.invalidate()
        let current = now()
        let next = scheduler.nextSettlementDate(from: current)
        let interval = max(1, next.timeIntervalSince(current) + 1)

        settlementTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.checkForSettlement()
                self?.scheduleNextSettlementCheck()
            }
        }
    }

    func generatePosterAndSave() {
        guard let posterExporter else {
            statusText = AppStrings.RuntimeStatus.posterUnavailable
            return
        }

        do {
            let url = try posterExporter.generateAndSaveLatestPoster()
            statusText = "\(AppStrings.RuntimeStatus.posterSavedPrefix)：\(url.lastPathComponent)"
        } catch {
            statusText = AppStrings.RuntimeStatus.posterSaveFailed
        }
    }

    func copyPosterToClipboard() {
        guard let posterExporter else {
            statusText = AppStrings.RuntimeStatus.posterUnavailable
            return
        }

        do {
            try posterExporter.generateAndCopyLatestPoster()
            statusText = AppStrings.RuntimeStatus.posterCopied
        } catch {
            statusText = AppStrings.RuntimeStatus.posterCopyFailed
        }
    }

    private static func makeLiveSettlementService(aggregator: MinuteBucketAggregator) -> DailySettling? {
        let settingsStore = SettingsStore()
        let windowProvider = SettingsTrackingWindowProvider(settingsStore: settingsStore)
        let calculator = DailyScoreCalculator()
        let notifier = NotificationService()

        guard let repository = makeLiveRepository() else {
            return nil
        }

        return DailySettlementService(
            aggregator: aggregator,
            windowProvider: windowProvider,
            calculator: calculator,
            repository: repository,
            notifier: notifier
        )
    }

    private static func makeLivePosterExporter() -> PosterExporting? {
        guard let repository = makeLiveRepository() else {
            return nil
        }

        guard let appDirectory = makeAppDirectory() else {
            return nil
        }
        let exportDirectory = appDirectory.appendingPathComponent("exports", isDirectory: true)

        return PosterExportService(
            repository: repository,
            renderer: PosterRenderer(),
            clipboard: SystemClipboardWriter(),
            exportDirectory: exportDirectory,
            fileManager: .default
        )
    }

    private static func makeLiveRepository() -> DailyRecordRepository? {
        guard let appDirectory = makeAppDirectory() else {
            return nil
        }
        let recordsURL = appDirectory.appendingPathComponent("daily-records.json")
        return try? DailyRecordRepository(database: Database(fileURL: recordsURL))
    }

    private static func makeAppDirectory() -> URL? {
        let fileManager = FileManager.default
        guard let supportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        let appDirectory = supportDirectory.appendingPathComponent("MoyuCounter", isDirectory: true)
        try? fileManager.createDirectory(at: appDirectory, withIntermediateDirectories: true)
        return appDirectory
    }
}
