import XCTest
@testable import MoyuCounter

final class MinuteBucketAggregatorTests: XCTestCase {
    func test_aggregator_counts_events_per_minute() {
        let aggregator = MinuteBucketAggregator()
        aggregator.record(timestamp: Date(timeIntervalSince1970: 60))
        aggregator.record(timestamp: Date(timeIntervalSince1970: 61))

        XCTAssertEqual(aggregator.count(forEpochMinute: 1), 2)
        XCTAssertEqual(aggregator.count(forEpochMinute: 0), 0)
    }
}
