import AppKit
import Foundation

enum PosterRendererError: Error {
    case bitmapCreateFailed
    case pngEncodeFailed
}

final class PosterRenderer {
    func render(report: DailyReportPresentation) throws -> Data {
        let template = PosterTemplate.for(report.label)
        let width = 1080
        let height = 1080

        guard let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: width,
            pixelsHigh: height,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bitmapFormat: [],
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else {
            throw PosterRendererError.bitmapCreateFailed
        }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)

        template.backgroundColor.setFill()
        NSBezierPath(rect: NSRect(x: 0, y: 0, width: width, height: height)).fill()

        let cardRect = NSRect(x: 70, y: 70, width: 940, height: 940)
        let cardPath = NSBezierPath(roundedRect: cardRect, xRadius: 40, yRadius: 40)
        template.cardColor.setFill()
        cardPath.fill()

        let headerRect = NSRect(x: 120, y: 820, width: 260, height: 44)
        let headerPath = NSBezierPath(roundedRect: headerRect, xRadius: 22, yRadius: 22)
        template.accentColor.setFill()
        headerPath.fill()

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .left

        NSString(string: "每日群聊战报").draw(
            in: headerRect.insetBy(dx: 18, dy: 8),
            withAttributes: [
                .font: NSFont.systemFont(ofSize: 24, weight: .bold),
                .foregroundColor: NSColor.white,
                .paragraphStyle: paragraph,
            ]
        )

        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 74),
            .foregroundColor: template.primaryTextColor,
            .paragraphStyle: paragraph,
        ]
        let scoreAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 42, weight: .semibold),
            .foregroundColor: template.primaryTextColor,
            .paragraphStyle: paragraph,
        ]
        let bodyAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 30, weight: .medium),
            .foregroundColor: template.secondaryTextColor,
            .paragraphStyle: paragraph,
        ]
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 24, weight: .regular),
            .foregroundColor: template.secondaryTextColor,
            .paragraphStyle: paragraph,
        ]

        NSString(string: report.title).draw(
            in: NSRect(x: 120, y: 700, width: 840, height: 110),
            withAttributes: titleAttributes
        )

        NSString(string: report.laborScoreText).draw(
            in: NSRect(x: 120, y: 620, width: 420, height: 60),
            withAttributes: scoreAttributes
        )

        NSString(string: report.moyuScoreText).draw(
            in: NSRect(x: 560, y: 620, width: 320, height: 60),
            withAttributes: scoreAttributes
        )

        drawTextBlock(
            text: report.verdict,
            rect: NSRect(x: 120, y: 500, width: 840, height: 96),
            font: NSFont.systemFont(ofSize: 34, weight: .bold),
            color: template.accentColor,
            alignment: .left
        )

        drawTextBlock(
            text: report.highlight,
            rect: NSRect(x: 120, y: 410, width: 840, height: 72),
            font: NSFont.systemFont(ofSize: 28, weight: .medium),
            color: template.secondaryTextColor,
            alignment: .left
        )

        for (index, stat) in report.stats.enumerated() {
            let statRect = NSRect(x: 120 + (index * 280), y: 220, width: 240, height: 130)
            let statPath = NSBezierPath(roundedRect: statRect, xRadius: 28, yRadius: 28)
            template.backgroundColor.withAlphaComponent(0.5).setFill()
            statPath.fill()

            NSString(string: stat.label).draw(
                in: NSRect(x: statRect.minX + 24, y: statRect.minY + 72, width: 190, height: 28),
                withAttributes: footerAttributes
            )
            NSString(string: stat.value).draw(
                in: NSRect(x: statRect.minX + 24, y: statRect.minY + 28, width: 190, height: 40),
                withAttributes: bodyAttributes
            )
        }

        NSString(string: "\(report.dateText) · \(AppStrings.App.name)").draw(
            in: NSRect(x: 120, y: 120, width: 840, height: 40),
            withAttributes: footerAttributes
        )

        NSGraphicsContext.restoreGraphicsState()

        guard let data = bitmap.representation(using: .png, properties: [:]) else {
            throw PosterRendererError.pngEncodeFailed
        }
        return data
    }

    private func drawTextBlock(
        text: String,
        rect: NSRect,
        font: NSFont,
        color: NSColor,
        alignment: NSTextAlignment
    ) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = alignment

        NSString(string: text).draw(
            in: rect,
            withAttributes: [
                .font: font,
                .foregroundColor: color,
                .paragraphStyle: paragraph,
            ]
        )
    }
}
