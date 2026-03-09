import XCTest
@testable import MoyuCounter

final class PosterRendererTests: XCTestCase {
    func test_renderer_returns_image_data_for_valid_result() throws {
        let renderer = PosterRenderer()

        let report = DailyReportPresentation(
            label: .moyuMaster,
            title: "摸鱼大师",
            laborScoreText: "劳动分 30",
            moyuScoreText: "摸鱼分 70",
            verdict: "Fish mode",
            highlight: "连续 120 分钟低活跃，堪称隐身办公。",
            stats: [
                .init(label: "活跃分钟", value: "40"),
                .init(label: "最长沉寂", value: "120 分钟"),
                .init(label: "统计范围", value: "480 分钟"),
            ],
            dateText: "2026年3月9日",
            shareText: "摸鱼大师 | 劳动分 30 · 摸鱼分 70"
        )
        let data = try renderer.render(report: report)

        XCTAssertFalse(data.isEmpty)
        XCTAssertEqual(Array(data.prefix(4)), [0x89, 0x50, 0x4E, 0x47])
    }
}
