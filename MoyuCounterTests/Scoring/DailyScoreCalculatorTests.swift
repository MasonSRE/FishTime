import XCTest
@testable import MoyuCounter

final class DailyScoreCalculatorTests: XCTestCase {
    func test_high_activity_day_is_classified_as_top_niuma() {
        let calculator = DailyScoreCalculator()

        let result = calculator.calculate(from: [
            .init(epm: 20, minutes: 480)
        ])

        XCTAssertGreaterThanOrEqual(result.laborScore, 75)
        XCTAssertEqual(result.label, .topNiuMa)
        XCTAssertEqual(result.oneLiner, "键盘冒火星，鼠标擦出电。")
    }

    func test_calculator_returns_activity_breakdown_for_report_generation() {
        let calculator = DailyScoreCalculator()

        let result = calculator.calculate(from: [
            .init(epm: 1, minutes: 2),
            .init(epm: 20, minutes: 3),
        ])

        XCTAssertEqual(result.trackedMinutes, 5)
        XCTAssertEqual(result.lowActivityMinutes, 2)
        XCTAssertEqual(result.highActivityMinutes, 3)
        XCTAssertEqual(result.longestIdleMinutes, 2)
    }

    func test_calculator_tracks_longest_idle_run_across_consecutive_low_activity_samples() {
        let calculator = DailyScoreCalculator()

        let result = calculator.calculate(from: [
            .init(epm: 1, minutes: 1),
            .init(epm: 1, minutes: 1),
            .init(epm: 20, minutes: 1),
            .init(epm: 1, minutes: 1),
        ])

        XCTAssertEqual(result.longestIdleMinutes, 2)
    }
}
