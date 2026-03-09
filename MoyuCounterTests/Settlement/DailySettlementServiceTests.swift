import XCTest
@testable import MoyuCounter

final class DailySettlementServiceTests: XCTestCase {
    func test_settlement_saves_record_and_posts_notification() throws {
        let aggregator = MinuteBucketAggregator()
        aggregator.record(timestamp: Date(timeIntervalSince1970: 0))
        aggregator.record(timestamp: Date(timeIntervalSince1970: 65))

        let repository = try DailyRecordRepository.inMemory()
        let notifier = CapturingNotifier()
        let service = DailySettlementService(
            aggregator: aggregator,
            windowProvider: StubTrackingWindowProvider(range: 0...1),
            calculator: DailyScoreCalculator(),
            repository: repository,
            notifier: notifier
        )

        let saved = try service.settle(for: Date(timeIntervalSince1970: 120))
        let latest = try repository.fetchLatest()

        XCTAssertEqual(saved, latest)
        XCTAssertEqual(latest?.activeMinutes, 2)
        XCTAssertEqual(notifier.messages.count, 1)
        XCTAssertTrue(notifier.messages[0].title.contains("今日已结算"))
    }

    func test_settlement_saves_report_metrics_for_later_sharing() throws {
        let aggregator = MinuteBucketAggregator()
        aggregator.record(timestamp: Date(timeIntervalSince1970: 0))
        aggregator.record(timestamp: Date(timeIntervalSince1970: 65))

        let repository = try DailyRecordRepository.inMemory()
        let service = DailySettlementService(
            aggregator: aggregator,
            windowProvider: StubTrackingWindowProvider(range: 0...1),
            calculator: DailyScoreCalculator(),
            repository: repository,
            notifier: CapturingNotifier()
        )

        let saved = try service.settle(for: Date(timeIntervalSince1970: 120))

        XCTAssertEqual(saved.moyuScore, 100 - saved.score)
        XCTAssertEqual(saved.trackedMinutes, 2)
        XCTAssertEqual(saved.activeMinutes, 2)
        XCTAssertEqual(saved.highActivityMinutes, 0)
        XCTAssertEqual(saved.lowActivityMinutes, 2)
        XCTAssertEqual(saved.longestIdleMinutes, 2)
    }

    func test_settlement_notification_uses_label_and_share_prompt_copy() throws {
        let aggregator = MinuteBucketAggregator()
        aggregator.record(timestamp: Date(timeIntervalSince1970: 0))

        let notifier = CapturingNotifier()
        let service = DailySettlementService(
            aggregator: aggregator,
            windowProvider: StubTrackingWindowProvider(range: 0...0),
            calculator: DailyScoreCalculator(),
            repository: try DailyRecordRepository.inMemory(),
            notifier: notifier
        )

        _ = try service.settle(for: Date(timeIntervalSince1970: 120))

        XCTAssertTrue(notifier.messages[0].title.contains("今日已结算"))
        XCTAssertTrue(notifier.messages[0].subtitle.contains("打开应用"))
    }
}

private struct StubTrackingWindowProvider: TrackingWindowProviding {
    let range: ClosedRange<Int>

    func epochMinuteRange(for date: Date) -> ClosedRange<Int> {
        range
    }
}

private final class CapturingNotifier: DailyResultNotifying {
    struct Message {
        let title: String
        let subtitle: String
    }

    private(set) var messages: [Message] = []

    func postDailyResult(title: String, subtitle: String) {
        messages.append(Message(title: title, subtitle: subtitle))
    }
}
