import AppKit
import Foundation

enum PosterRendererError: Error {
    case bitmapCreateFailed
    case pngEncodeFailed
}

final class PosterRenderer {
    func render(report: DailyReportPresentation) throws -> Data {
        let template = PosterTemplate.for(report.label, style: report.templateStyle)
        let canvasSize = canvasSize(for: report.templateStyle)

        guard let bitmap = makeBitmap(width: Int(canvasSize.width), height: Int(canvasSize.height)) else {
            throw PosterRendererError.bitmapCreateFailed
        }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)

        switch report.templateStyle {
        case .standard:
            renderStandardTemplate(report: report, template: template, canvasSize: canvasSize)
        case .certificate:
            renderCertificateTemplate(report: report, template: template, canvasSize: canvasSize)
        case .deskLog:
            renderDeskLogTemplate(report: report, template: template, canvasSize: canvasSize)
        }

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

    private func makeBitmap(width: Int, height: Int) -> NSBitmapImageRep? {
        NSBitmapImageRep(
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
        )
    }

    private func canvasSize(for style: ReportTemplateStyle) -> NSSize {
        switch style {
        case .certificate:
            return NSSize(width: 1080, height: 1350)
        case .standard, .deskLog:
            return NSSize(width: 1080, height: 1080)
        }
    }

    private func renderStandardTemplate(
        report: DailyReportPresentation,
        template: PosterTemplate,
        canvasSize: NSSize
    ) {
        fillBackground(template.backgroundColor, size: canvasSize)

        let cardRect = NSRect(x: 70, y: 70, width: 940, height: 940)
        fillRoundedRect(cardRect, radius: 40, color: template.cardColor)

        let headerRect = NSRect(x: 120, y: 820, width: 260, height: 44)
        fillRoundedRect(headerRect, radius: 22, color: template.accentColor)
        drawTextBlock(
            text: "每日群聊战报",
            rect: headerRect.insetBy(dx: 18, dy: 8),
            font: NSFont.systemFont(ofSize: 24, weight: .bold),
            color: .white,
            alignment: .left
        )

        drawTextBlock(
            text: report.title,
            rect: NSRect(x: 120, y: 700, width: 840, height: 110),
            font: NSFont.boldSystemFont(ofSize: 74),
            color: template.primaryTextColor,
            alignment: .left
        )

        drawTextBlock(
            text: report.laborScoreText,
            rect: NSRect(x: 120, y: 620, width: 420, height: 60),
            font: NSFont.systemFont(ofSize: 42, weight: .semibold),
            color: template.primaryTextColor,
            alignment: .left
        )
        drawTextBlock(
            text: report.moyuScoreText,
            rect: NSRect(x: 560, y: 620, width: 320, height: 60),
            font: NSFont.systemFont(ofSize: 42, weight: .semibold),
            color: template.primaryTextColor,
            alignment: .left
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

        drawStatGrid(
            stats: report.stats,
            startX: 120,
            y: 220,
            width: 240,
            height: 130,
            gap: 40,
            fillColor: template.emphasisFillColor,
            primaryTextColor: template.primaryTextColor,
            secondaryTextColor: template.secondaryTextColor
        )

        drawTextBlock(
            text: "\(report.dateText) · \(AppStrings.App.name)",
            rect: NSRect(x: 120, y: 120, width: 840, height: 40),
            font: NSFont.systemFont(ofSize: 24, weight: .regular),
            color: template.secondaryTextColor,
            alignment: .left
        )
    }

    private func renderCertificateTemplate(
        report: DailyReportPresentation,
        template: PosterTemplate,
        canvasSize: NSSize
    ) {
        fillBackground(template.backgroundColor, size: canvasSize)

        let frameRect = NSRect(x: 70, y: 70, width: canvasSize.width - 140, height: canvasSize.height - 140)
        fillRoundedRect(frameRect, radius: 48, color: template.cardColor)
        strokeRoundedRect(frameRect.insetBy(dx: 16, dy: 16), radius: 40, color: template.accentColor, lineWidth: 6)

        drawTextBlock(
            text: "今日奖状",
            rect: NSRect(x: 200, y: 1130, width: 680, height: 50),
            font: NSFont.systemFont(ofSize: 30, weight: .black),
            color: template.accentColor,
            alignment: .center
        )
        drawTextBlock(
            text: report.title,
            rect: NSRect(x: 150, y: 980, width: 780, height: 120),
            font: NSFont.boldSystemFont(ofSize: 76),
            color: template.primaryTextColor,
            alignment: .center
        )
        drawTextBlock(
            text: report.verdict,
            rect: NSRect(x: 160, y: 875, width: 760, height: 88),
            font: NSFont.systemFont(ofSize: 32, weight: .bold),
            color: template.secondaryTextColor,
            alignment: .center
        )

        let scoreRect = NSRect(x: 180, y: 720, width: 720, height: 120)
        fillRoundedRect(scoreRect, radius: 32, color: template.emphasisFillColor)
        drawTextBlock(
            text: "\(report.laborScoreText) · \(report.moyuScoreText)",
            rect: scoreRect.insetBy(dx: 24, dy: 28),
            font: NSFont.systemFont(ofSize: 36, weight: .semibold),
            color: template.primaryTextColor,
            alignment: .center
        )
        drawTextBlock(
            text: report.highlight,
            rect: NSRect(x: 180, y: 610, width: 720, height: 84),
            font: NSFont.systemFont(ofSize: 28, weight: .medium),
            color: template.secondaryTextColor,
            alignment: .center
        )

        for (index, stat) in report.stats.enumerated() {
            let rect = NSRect(x: 180, y: 470 - (index * 120), width: 720, height: 92)
            fillRoundedRect(rect, radius: 24, color: template.backgroundColor.withAlphaComponent(0.55))
            drawTextBlock(
                text: stat.label,
                rect: NSRect(x: rect.minX + 30, y: rect.minY + 46, width: 240, height: 24),
                font: NSFont.systemFont(ofSize: 24, weight: .medium),
                color: template.secondaryTextColor,
                alignment: .left
            )
            drawTextBlock(
                text: stat.value,
                rect: NSRect(x: rect.minX + 30, y: rect.minY + 16, width: 420, height: 28),
                font: NSFont.systemFont(ofSize: 28, weight: .semibold),
                color: template.primaryTextColor,
                alignment: .left
            )
        }

        drawTextBlock(
            text: "\(report.dateText) · \(AppStrings.App.name)",
            rect: NSRect(x: 180, y: 120, width: 720, height: 36),
            font: NSFont.systemFont(ofSize: 24, weight: .regular),
            color: template.secondaryTextColor,
            alignment: .center
        )
    }

    private func renderDeskLogTemplate(
        report: DailyReportPresentation,
        template: PosterTemplate,
        canvasSize: NSSize
    ) {
        fillBackground(template.backgroundColor, size: canvasSize)

        let panelRect = NSRect(x: 56, y: 56, width: canvasSize.width - 112, height: canvasSize.height - 112)
        fillRoundedRect(panelRect, radius: 36, color: template.cardColor)

        let bannerRect = NSRect(x: 90, y: 910, width: 900, height: 88)
        fillRoundedRect(bannerRect, radius: 24, color: template.accentColor)
        drawTextBlock(
            text: "工位日报 / 今日战报",
            rect: bannerRect.insetBy(dx: 28, dy: 22),
            font: NSFont.systemFont(ofSize: 34, weight: .black),
            color: template.backgroundColor,
            alignment: .left
        )

        drawTextBlock(
            text: report.title,
            rect: NSRect(x: 100, y: 760, width: 540, height: 120),
            font: NSFont.boldSystemFont(ofSize: 72),
            color: template.primaryTextColor,
            alignment: .left
        )
        drawTextBlock(
            text: report.verdict,
            rect: NSRect(x: 100, y: 650, width: 520, height: 90),
            font: NSFont.systemFont(ofSize: 30, weight: .bold),
            color: template.accentColor,
            alignment: .left
        )
        drawTextBlock(
            text: report.highlight,
            rect: NSRect(x: 100, y: 545, width: 520, height: 84),
            font: NSFont.systemFont(ofSize: 26, weight: .medium),
            color: template.secondaryTextColor,
            alignment: .left
        )

        let scoreCard = NSRect(x: 670, y: 620, width: 290, height: 220)
        fillRoundedRect(scoreCard, radius: 28, color: template.emphasisFillColor)
        drawTextBlock(
            text: report.laborScoreText,
            rect: NSRect(x: scoreCard.minX + 24, y: scoreCard.minY + 120, width: 230, height: 40),
            font: NSFont.systemFont(ofSize: 30, weight: .bold),
            color: template.primaryTextColor,
            alignment: .left
        )
        drawTextBlock(
            text: report.moyuScoreText,
            rect: NSRect(x: scoreCard.minX + 24, y: scoreCard.minY + 68, width: 230, height: 40),
            font: NSFont.systemFont(ofSize: 30, weight: .bold),
            color: template.primaryTextColor,
            alignment: .left
        )

        for (index, stat) in report.stats.enumerated() {
            let rect = NSRect(x: 100, y: 380 - (index * 108), width: 860, height: 88)
            fillRoundedRect(rect, radius: 24, color: template.backgroundColor.withAlphaComponent(0.24))
            drawTextBlock(
                text: stat.label,
                rect: NSRect(x: rect.minX + 26, y: rect.minY + 46, width: 240, height: 22),
                font: NSFont.systemFont(ofSize: 22, weight: .medium),
                color: template.secondaryTextColor,
                alignment: .left
            )
            drawTextBlock(
                text: stat.value,
                rect: NSRect(x: rect.minX + 26, y: rect.minY + 14, width: 360, height: 28),
                font: NSFont.systemFont(ofSize: 28, weight: .semibold),
                color: template.primaryTextColor,
                alignment: .left
            )
        }

        drawTextBlock(
            text: "\(report.dateText) · \(AppStrings.App.name)",
            rect: NSRect(x: 100, y: 110, width: 860, height: 36),
            font: NSFont.systemFont(ofSize: 24, weight: .regular),
            color: template.secondaryTextColor,
            alignment: .left
        )
    }

    private func fillBackground(_ color: NSColor, size: NSSize) {
        color.setFill()
        NSBezierPath(rect: NSRect(origin: .zero, size: size)).fill()
    }

    private func fillRoundedRect(_ rect: NSRect, radius: CGFloat, color: NSColor) {
        color.setFill()
        NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
    }

    private func strokeRoundedRect(_ rect: NSRect, radius: CGFloat, color: NSColor, lineWidth: CGFloat) {
        color.setStroke()
        let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
        path.lineWidth = lineWidth
        path.stroke()
    }

    private func drawStatGrid(
        stats: [DailyReportStat],
        startX: Int,
        y: Int,
        width: Int,
        height: Int,
        gap: Int,
        fillColor: NSColor,
        primaryTextColor: NSColor,
        secondaryTextColor: NSColor
    ) {
        for (index, stat) in stats.enumerated() {
            let statRect = NSRect(x: startX + (index * (width + gap)), y: y, width: width, height: height)
            fillRoundedRect(statRect, radius: 28, color: fillColor)
            drawTextBlock(
                text: stat.label,
                rect: NSRect(x: statRect.minX + 24, y: statRect.minY + 72, width: 190, height: 28),
                font: NSFont.systemFont(ofSize: 24, weight: .regular),
                color: secondaryTextColor,
                alignment: .left
            )
            drawTextBlock(
                text: stat.value,
                rect: NSRect(x: statRect.minX + 24, y: statRect.minY + 28, width: 190, height: 40),
                font: NSFont.systemFont(ofSize: 30, weight: .medium),
                color: primaryTextColor,
                alignment: .left
            )
        }
    }
}
