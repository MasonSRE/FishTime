import Foundation

protocol DailyResultNotifying {
    func postDailyResult(title: String, subtitle: String)
}

extension NotificationService: DailyResultNotifying {}

protocol DailySettling: AnyObject {
    @discardableResult
    func settle(for date: Date) throws -> DailyRecord
}

final class DailySettlementService: DailySettling {
    private let aggregator: MinuteBucketAggregator
    private let windowProvider: TrackingWindowProviding
    private let calculator: DailyScoreCalculator
    private let repository: DailyRecordRepository
    private let notifier: DailyResultNotifying

    init(
        aggregator: MinuteBucketAggregator,
        windowProvider: TrackingWindowProviding,
        calculator: DailyScoreCalculator,
        repository: DailyRecordRepository,
        notifier: DailyResultNotifying
    ) {
        self.aggregator = aggregator
        self.windowProvider = windowProvider
        self.calculator = calculator
        self.repository = repository
        self.notifier = notifier
    }

    @discardableResult
    func settle(for date: Date) throws -> DailyRecord {
        let minuteRange = windowProvider.epochMinuteRange(for: date)
        let counts = aggregator.counts(in: minuteRange)
        let samples = counts.map { MinuteActivitySample(epm: $0, minutes: 1) }
        let scoreResult = calculator.calculate(from: samples)

        let activeMinutes = counts.filter { $0 > 0 }.count
        let record = DailyRecord(
            date: date,
            score: scoreResult.laborScore,
            moyuScore: scoreResult.moyuScore,
            label: scoreResult.label.rawValue,
            activeMinutes: activeMinutes,
            trackedMinutes: scoreResult.trackedMinutes,
            highActivityMinutes: scoreResult.highActivityMinutes,
            lowActivityMinutes: scoreResult.lowActivityMinutes,
            longestIdleMinutes: scoreResult.longestIdleMinutes
        )

        try repository.save(record)

        notifier.postDailyResult(
            title: "\(AppStrings.Notification.settledTitlePrefix)：\(scoreResult.label.displayTitle)",
            subtitle: "摸鱼分 \(scoreResult.moyuScore) · \(AppStrings.Notification.openReportPrompt)"
        )

        return record
    }
}

private extension DailyScoreLabel {
    var displayTitle: String {
        switch self {
        case .topNiuMa:
            return AppStrings.Score.topNiuMaTitle
        case .balancedHuman:
            return AppStrings.Score.balancedHumanTitle
        case .moyuMaster:
            return AppStrings.Score.moyuMasterTitle
        }
    }
}
