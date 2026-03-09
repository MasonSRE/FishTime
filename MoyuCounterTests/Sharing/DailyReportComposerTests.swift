import XCTest
@testable import MoyuCounter

final class DailyReportComposerTests: XCTestCase {
    func test_composer_builds_group_share_presentation_for_moyu_record() {
        let composer = DailyReportComposer(randomIndexProvider: { _, count in count - 1 })
        let record = DailyRecord(
            date: Date(timeIntervalSince1970: 86_400),
            score: 32,
            moyuScore: 68,
            label: DailyScoreLabel.moyuMaster.rawValue,
            activeMinutes: 40,
            trackedMinutes: 480,
            highActivityMinutes: 12,
            lowActivityMinutes: 300,
            longestIdleMinutes: 96
        )

        let presentation = composer.makePresentation(from: record, templateStyle: .standard)

        XCTAssertEqual(presentation.title, "摸鱼大师")
        XCTAssertEqual(presentation.laborScoreText, "劳动分 32")
        XCTAssertEqual(presentation.moyuScoreText, "摸鱼分 68")
        XCTAssertFalse(presentation.verdict.isEmpty)
        XCTAssertTrue(presentation.highlight.contains("96"))
        XCTAssertEqual(presentation.stats.count, 3)
        XCTAssertEqual(presentation.templateStyle, .standard)
    }

    func test_composer_keeps_scores_stable_across_templates_but_changes_template_specific_copy() {
        let composer = DailyReportComposer(randomIndexProvider: { _, _ in 0 })
        let record = DailyRecord(
            date: Date(timeIntervalSince1970: 86_400),
            score: 55,
            moyuScore: 45,
            label: DailyScoreLabel.balancedHuman.rawValue,
            activeMinutes: 180,
            trackedMinutes: 480,
            highActivityMinutes: 120,
            lowActivityMinutes: 120,
            longestIdleMinutes: 18
        )

        let standard = composer.makePresentation(from: record, templateStyle: .standard)
        let certificate = composer.makePresentation(from: record, templateStyle: .certificate)

        XCTAssertEqual(standard.laborScoreText, certificate.laborScoreText)
        XCTAssertEqual(standard.moyuScoreText, certificate.moyuScoreText)
        XCTAssertEqual(standard.highlight, certificate.highlight)
        XCTAssertEqual(certificate.templateStyle, .certificate)
        XCTAssertNotEqual(standard.shareText, certificate.shareText)
        XCTAssertNotEqual(standard.stats, certificate.stats)
    }
}
