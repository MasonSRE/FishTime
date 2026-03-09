import Foundation
import XCTest
@testable import MoyuCounter

final class PosterExportServiceTests: XCTestCase {
    func test_generate_and_save_latest_poster_returns_file_url() throws {
        let repository = try DailyRecordRepository.inMemory()
        try repository.save(DailyRecord(date: Date(), score: 66, label: "balancedHuman", activeMinutes: 120))

        let fileManager = FileManager.default
        let exportDirectory = fileManager.temporaryDirectory
            .appendingPathComponent("moyu-poster-export-tests-\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: exportDirectory, withIntermediateDirectories: true)

        let renderer = StubPosterRenderer(data: Data([0xDE, 0xAD, 0xBE, 0xEF]))
        let clipboard = StubClipboardWriter()

        let service = PosterExportService(
            repository: repository,
            renderer: renderer,
            clipboard: clipboard,
            exportDirectory: exportDirectory,
            fileManager: fileManager
        )

        let url = try service.generateAndSaveLatestPoster()

        XCTAssertTrue(fileManager.fileExists(atPath: url.path))
        XCTAssertEqual(try Data(contentsOf: url), Data([0xDE, 0xAD, 0xBE, 0xEF]))
    }

    func test_generate_and_copy_latest_poster_writes_clipboard_data() throws {
        let repository = try DailyRecordRepository.inMemory()
        try repository.save(DailyRecord(date: Date(), score: 80, label: "topNiuMa", activeMinutes: 300))

        let renderer = StubPosterRenderer(data: Data([0xAA, 0xBB]))
        let clipboard = StubClipboardWriter()

        let service = PosterExportService(
            repository: repository,
            renderer: renderer,
            clipboard: clipboard,
            exportDirectory: FileManager.default.temporaryDirectory,
            fileManager: .default
        )

        try service.generateAndCopyLatestPoster()

        XCTAssertEqual(clipboard.writtenData, Data([0xAA, 0xBB]))
        XCTAssertTrue(clipboard.writtenText?.contains("顶级牛马") ?? false)
        XCTAssertTrue(clipboard.writtenText?.contains("劳动分 80") ?? false)
    }

    func test_generate_and_copy_latest_poster_renders_report_presentation() throws {
        let repository = try DailyRecordRepository.inMemory()
        try repository.save(
            DailyRecord(
                date: Date(),
                score: 80,
                moyuScore: 20,
                label: DailyScoreLabel.topNiuMa.rawValue,
                activeMinutes: 300,
                trackedMinutes: 480,
                highActivityMinutes: 280,
                lowActivityMinutes: 40,
                longestIdleMinutes: 12
            )
        )

        let renderer = CapturingPosterRenderer(data: Data([0xAA]))
        let service = PosterExportService(
            repository: repository,
            renderer: renderer,
            clipboard: StubClipboardWriter(),
            exportDirectory: FileManager.default.temporaryDirectory,
            fileManager: .default
        )

        try service.generateAndCopyLatestPoster()

        XCTAssertEqual(renderer.lastPresentation?.title, "顶级牛马")
        XCTAssertFalse(renderer.lastPresentation?.highlight.isEmpty ?? true)
    }
}

private final class StubPosterRenderer: PosterRendering {
    let data: Data

    init(data: Data) {
        self.data = data
    }

    func render(report: DailyReportPresentation) throws -> Data {
        data
    }
}

private final class CapturingPosterRenderer: PosterRendering {
    let data: Data
    private(set) var lastPresentation: DailyReportPresentation?

    init(data: Data) {
        self.data = data
    }

    func render(report: DailyReportPresentation) throws -> Data {
        lastPresentation = report
        return data
    }
}

private final class StubClipboardWriter: ClipboardWriting {
    private(set) var writtenData: Data?
    private(set) var writtenText: String?

    func writeSharePayload(imageData: Data, text: String) {
        writtenData = imageData
        writtenText = text
    }
}
