import AppKit
import Foundation

protocol PosterRendering: AnyObject {
    func render(report: DailyReportPresentation) throws -> Data
}

extension PosterRenderer: PosterRendering {}

protocol ClipboardWriting: AnyObject {
    func writeSharePayload(imageData: Data, text: String)
}

final class SystemClipboardWriter: ClipboardWriting {
    func writeSharePayload(imageData: Data, text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setData(imageData, forType: .png)
        pasteboard.setString(text, forType: .string)
    }
}

protocol PosterExporting: AnyObject {
    func generateAndSaveLatestPoster() throws -> URL
    func generateAndCopyLatestPoster() throws
    func generateAndCopyPoster(for record: DailyRecord) throws
}

enum PosterExportError: Error {
    case noDailyRecord
}

final class PosterExportService: PosterExporting {
    private let repository: DailyRecordRepository
    private let renderer: PosterRendering
    private let settingsStore: SettingsStore
    private let composer: DailyReportComposer
    private let clipboard: ClipboardWriting
    private let exportDirectory: URL
    private let fileManager: FileManager

    init(
        repository: DailyRecordRepository,
        renderer: PosterRendering,
        settingsStore: SettingsStore = SettingsStore(),
        composer: DailyReportComposer = DailyReportComposer(),
        clipboard: ClipboardWriting,
        exportDirectory: URL,
        fileManager: FileManager
    ) {
        self.repository = repository
        self.renderer = renderer
        self.settingsStore = settingsStore
        self.composer = composer
        self.clipboard = clipboard
        self.exportDirectory = exportDirectory
        self.fileManager = fileManager
    }

    func generateAndSaveLatestPoster() throws -> URL {
        let payload = try renderLatest()
        try fileManager.createDirectory(at: exportDirectory, withIntermediateDirectories: true)

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let filename = "moyu-poster-\(formatter.string(from: Date())).png".replacingOccurrences(of: ":", with: "-")
        let outputURL = exportDirectory.appendingPathComponent(filename)
        try payload.data.write(to: outputURL, options: .atomic)
        return outputURL
    }

    func generateAndCopyLatestPoster() throws {
        let payload = try renderLatest()
        clipboard.writeSharePayload(imageData: payload.data, text: payload.report.shareText)
    }

    func generateAndCopyPoster(for record: DailyRecord) throws {
        let payload = try render(record: record)
        clipboard.writeSharePayload(imageData: payload.data, text: payload.report.shareText)
    }

    private func renderLatest() throws -> RenderedReportPayload {
        guard let latest = try repository.fetchLatest() else {
            throw PosterExportError.noDailyRecord
        }

        return try render(record: latest)
    }

    private func render(record: DailyRecord) throws -> RenderedReportPayload {
        let report = composer.makePresentation(
            from: record,
            templateStyle: settingsStore.selectedReportTemplate
        )
        let data = try renderer.render(report: report)
        return RenderedReportPayload(data: data, report: report)
    }
}

private struct RenderedReportPayload {
    let data: Data
    let report: DailyReportPresentation
}
