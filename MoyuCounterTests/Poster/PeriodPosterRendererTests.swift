import XCTest
@testable import MoyuCounter

final class PeriodPosterRendererTests: XCTestCase {
    func test_period_renderer_returns_png_data() throws {
        let renderer = PeriodPosterRenderer()
        let presentation = PeriodReportPresentation(
            kind: .weekly,
            title: "本周摸鱼纪念卡",
            subtitle: "截至今日",
            verdict: "本周属于人类平衡态",
            stats: [
                .init(label: "记录天数", value: "4"),
                .init(label: "平均劳动分", value: "61"),
                .init(label: "总活跃分钟", value: "820"),
                .init(label: "最长沉寂分钟", value: "48"),
            ],
            highlights: [
                "最拼一天：周三，劳动分 78",
                "最会摸一天：周五，摸鱼分 66",
            ],
            footer: "03.03 - 03.09 · 摸鱼统计器",
            shareText: "本周摸鱼纪念卡"
        )

        let data = try renderer.render(report: presentation)

        XCTAssertEqual(Array(data.prefix(4)), [0x89, 0x50, 0x4E, 0x47])
    }
}
