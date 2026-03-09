import Combine
import Foundation

@MainActor
final class AppDependencies: ObservableObject {
    let settingsStore: SettingsStore
    let permissionViewModel: PermissionOnboardingViewModel
    let menuBarViewModel: MenuBarViewModel
    let historyViewModel: HistoryViewModel
    let todayReportViewModel: TodayReportViewModel
    let windowRouter: WindowRouter

    private let repository: DailyRecordRepository
    private let aggregator: MinuteBucketAggregator
    private let notificationService: NotificationService

    init() {
        settingsStore = SettingsStore()
        aggregator = MinuteBucketAggregator()
        repository = Self.makeRepository()
        windowRouter = WindowRouter()
        notificationService = NotificationService()

        let permissionManager = AccessibilityPermissionManager()
        let tracker = ActivityTrackingCoordinator(
            permissionManager: permissionManager,
            eventSource: AppKitActivityEventSource(),
            collector: ActivityCollector(aggregator: aggregator)
        )
        let scheduler = DayEndScheduler()
        let settlementService = DailySettlementService(
            aggregator: aggregator,
            windowProvider: SettingsTrackingWindowProvider(settingsStore: settingsStore),
            calculator: DailyScoreCalculator(),
            repository: repository,
            notifier: notificationService
        )
        let posterExporter = PosterExportService(
            repository: repository,
            renderer: PosterRenderer(),
            clipboard: SystemClipboardWriter(),
            exportDirectory: Self.makeAppDirectory().appendingPathComponent("exports", isDirectory: true),
            fileManager: .default
        )

        permissionViewModel = PermissionOnboardingViewModel(permissionManager: permissionManager)
        menuBarViewModel = MenuBarViewModel(
            aggregator: aggregator,
            tracker: tracker,
            scheduler: scheduler,
            settlementService: settlementService,
            posterExporter: posterExporter
        )
        historyViewModel = HistoryViewModel(
            repository: repository,
            posterExporter: posterExporter
        )
        todayReportViewModel = TodayReportViewModel(
            repository: repository,
            settingsStore: settingsStore
        )
        notificationService.configure { [windowRouter] in
            windowRouter.openMainWindow()
        }
    }

    func resetLocalData() {
        try? repository.reset()
        aggregator.reset()
        menuBarViewModel.updateTodayEventCount(0)
        historyViewModel.reload()
        todayReportViewModel.reload()
    }

    private static func makeRepository() -> DailyRecordRepository {
        let recordsURL = makeAppDirectory().appendingPathComponent("daily-records.json")
        if let repository = try? DailyRecordRepository(database: Database(fileURL: recordsURL)) {
            return repository
        }
        if let inMemoryRepository = try? DailyRecordRepository.inMemory() {
            return inMemoryRepository
        }
        fatalError("Unable to initialize local repository.")
    }

    private static func makeAppDirectory() -> URL {
        let fileManager = FileManager.default
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? fileManager.temporaryDirectory
        let directory = base.appendingPathComponent("MoyuCounter", isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}
