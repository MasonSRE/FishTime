import AppKit
import Foundation

final class PeriodPosterRenderer {
    func render(report: PeriodReportPresentation) throws -> Data {
        let canvasSize = NSSize(width: 1080, height: 1350)

        guard let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(canvasSize.width),
            pixelsHigh: Int(canvasSize.height),
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

        let background = NSColor(calibratedRed: 0.95, green: 0.93, blue: 0.88, alpha: 1)
        background.setFill()
        NSBezierPath(rect: NSRect(origin: .zero, size: canvasSize)).fill()

        let cardRect = NSRect(x: 72, y: 72, width: 936, height: 1206)
        fillRoundedRect(cardRect, radius: 40, color: .white)

        drawText(
            report.title,
            in: NSRect(x: 120, y: 1090, width: 840, height: 70),
            font: .boldSystemFont(ofSize: 54),
            color: NSColor(calibratedRed: 0.22, green: 0.18, blue: 0.11, alpha: 1),
            alignment: .center
        )
        drawText(
            report.subtitle,
            in: NSRect(x: 160, y: 1038, width: 760, height: 36),
            font: .systemFont(ofSize: 24, weight: .medium),
            color: NSColor(calibratedRed: 0.47, green: 0.38, blue: 0.25, alpha: 1),
            alignment: .center
        )
        drawText(
            report.verdict,
            in: NSRect(x: 160, y: 930, width: 760, height: 70),
            font: .systemFont(ofSize: 34, weight: .bold),
            color: NSColor(calibratedRed: 0.45, green: 0.30, blue: 0.08, alpha: 1),
            alignment: .center
        )

        for (index, stat) in report.stats.enumerated() {
            let column = index % 2
            let row = index / 2
            let rect = NSRect(
                x: 120 + CGFloat(column) * 420,
                y: 720 - CGFloat(row) * 150,
                width: 360,
                height: 120
            )
            fillRoundedRect(rect, radius: 26, color: NSColor(calibratedRed: 0.96, green: 0.91, blue: 0.80, alpha: 1))
            drawText(
                stat.label,
                in: NSRect(x: rect.minX + 24, y: rect.minY + 66, width: 220, height: 24),
                font: .systemFont(ofSize: 22, weight: .medium),
                color: NSColor(calibratedRed: 0.52, green: 0.41, blue: 0.24, alpha: 1),
                alignment: .left
            )
            drawText(
                stat.value,
                in: NSRect(x: rect.minX + 24, y: rect.minY + 26, width: 220, height: 34),
                font: .systemFont(ofSize: 32, weight: .bold),
                color: NSColor(calibratedRed: 0.21, green: 0.16, blue: 0.10, alpha: 1),
                alignment: .left
            )
        }

        for (index, highlight) in report.highlights.enumerated() {
            let rect = NSRect(x: 120, y: 410 - CGFloat(index) * 110, width: 840, height: 88)
            fillRoundedRect(rect, radius: 24, color: NSColor(calibratedRed: 0.91, green: 0.96, blue: 0.98, alpha: 1))
            drawText(
                highlight,
                in: NSRect(x: rect.minX + 28, y: rect.minY + 24, width: 760, height: 40),
                font: .systemFont(ofSize: 28, weight: .semibold),
                color: NSColor(calibratedRed: 0.13, green: 0.29, blue: 0.42, alpha: 1),
                alignment: .left
            )
        }

        drawText(
            report.footer,
            in: NSRect(x: 120, y: 118, width: 840, height: 32),
            font: .systemFont(ofSize: 24, weight: .regular),
            color: NSColor(calibratedRed: 0.47, green: 0.38, blue: 0.25, alpha: 1),
            alignment: .center
        )

        NSGraphicsContext.restoreGraphicsState()

        guard let data = bitmap.representation(using: .png, properties: [:]) else {
            throw PosterRendererError.pngEncodeFailed
        }

        return data
    }

    private func drawText(
        _ text: String,
        in rect: NSRect,
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

    private func fillRoundedRect(_ rect: NSRect, radius: CGFloat, color: NSColor) {
        color.setFill()
        NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
    }
}
