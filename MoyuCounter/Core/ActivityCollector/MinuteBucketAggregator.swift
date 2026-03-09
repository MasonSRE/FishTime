import Foundation

final class MinuteBucketAggregator {
    private var buckets: [Int: Int] = [:]
    private let lock = NSLock()

    func record(timestamp: Date) {
        let epochMinute = Int(timestamp.timeIntervalSince1970) / 60
        lock.lock()
        buckets[epochMinute, default: 0] += 1
        lock.unlock()
    }

    func count(forEpochMinute minute: Int) -> Int {
        lock.lock()
        defer { lock.unlock() }
        return buckets[minute] ?? 0
    }

    func totalCount() -> Int {
        lock.lock()
        defer { lock.unlock() }
        return buckets.values.reduce(0, +)
    }

    func counts(in range: ClosedRange<Int>) -> [Int] {
        lock.lock()
        defer { lock.unlock() }
        return range.map { buckets[$0] ?? 0 }
    }

    func reset() {
        lock.lock()
        buckets.removeAll()
        lock.unlock()
    }
}
