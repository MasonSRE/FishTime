import Foundation

protocol ActivityHandling: AnyObject {
    func handle(_ event: ActivityEvent)
}

final class ActivityCollector: ActivityHandling {
    private let aggregator: MinuteBucketAggregator

    init(aggregator: MinuteBucketAggregator = MinuteBucketAggregator()) {
        self.aggregator = aggregator
    }

    func handle(_ event: ActivityEvent) {
        aggregator.record(timestamp: event.timestamp)
    }
}
