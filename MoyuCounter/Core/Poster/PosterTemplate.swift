import AppKit

struct PosterTemplate {
    let backgroundColor: NSColor
    let cardColor: NSColor
    let accentColor: NSColor
    let primaryTextColor: NSColor
    let secondaryTextColor: NSColor
    let emphasisFillColor: NSColor

    static func `for`(_ label: DailyScoreLabel, style: ReportTemplateStyle) -> PosterTemplate {
        switch style {
        case .standard:
            return standardTemplate(for: label)
        case .certificate:
            return certificateTemplate(for: label)
        case .deskLog:
            return deskLogTemplate(for: label)
        }
    }

    private static func standardTemplate(for label: DailyScoreLabel) -> PosterTemplate {
        switch label {
        case .topNiuMa:
            return PosterTemplate(
                backgroundColor: NSColor(calibratedRed: 0.96, green: 0.82, blue: 0.37, alpha: 1),
                cardColor: NSColor(calibratedRed: 1.0, green: 0.97, blue: 0.88, alpha: 0.96),
                accentColor: NSColor(calibratedRed: 0.52, green: 0.28, blue: 0.06, alpha: 1),
                primaryTextColor: NSColor(calibratedRed: 0.18, green: 0.12, blue: 0.04, alpha: 1),
                secondaryTextColor: NSColor(calibratedRed: 0.33, green: 0.23, blue: 0.09, alpha: 1),
                emphasisFillColor: NSColor(calibratedRed: 0.88, green: 0.73, blue: 0.33, alpha: 0.4)
            )
        case .balancedHuman:
            return PosterTemplate(
                backgroundColor: NSColor(calibratedRed: 0.61, green: 0.78, blue: 0.98, alpha: 1),
                cardColor: NSColor(calibratedRed: 0.93, green: 0.97, blue: 1.0, alpha: 0.96),
                accentColor: NSColor(calibratedRed: 0.08, green: 0.31, blue: 0.59, alpha: 1),
                primaryTextColor: NSColor(calibratedRed: 0.07, green: 0.20, blue: 0.34, alpha: 1),
                secondaryTextColor: NSColor(calibratedRed: 0.15, green: 0.35, blue: 0.55, alpha: 1),
                emphasisFillColor: NSColor(calibratedRed: 0.52, green: 0.72, blue: 0.94, alpha: 0.35)
            )
        case .moyuMaster:
            return PosterTemplate(
                backgroundColor: NSColor(calibratedRed: 0.55, green: 0.88, blue: 0.68, alpha: 1),
                cardColor: NSColor(calibratedRed: 0.93, green: 0.99, blue: 0.95, alpha: 0.96),
                accentColor: NSColor(calibratedRed: 0.06, green: 0.39, blue: 0.22, alpha: 1),
                primaryTextColor: NSColor(calibratedRed: 0.05, green: 0.21, blue: 0.13, alpha: 1),
                secondaryTextColor: NSColor(calibratedRed: 0.12, green: 0.38, blue: 0.24, alpha: 1),
                emphasisFillColor: NSColor(calibratedRed: 0.30, green: 0.78, blue: 0.49, alpha: 0.28)
            )
        }
    }

    private static func certificateTemplate(for label: DailyScoreLabel) -> PosterTemplate {
        let base = standardTemplate(for: label)
        return PosterTemplate(
            backgroundColor: NSColor(calibratedRed: 0.99, green: 0.95, blue: 0.87, alpha: 1),
            cardColor: NSColor(calibratedRed: 0.98, green: 0.92, blue: 0.78, alpha: 0.96),
            accentColor: base.accentColor,
            primaryTextColor: NSColor(calibratedRed: 0.26, green: 0.19, blue: 0.10, alpha: 1),
            secondaryTextColor: NSColor(calibratedRed: 0.45, green: 0.34, blue: 0.19, alpha: 1),
            emphasisFillColor: NSColor(calibratedRed: 0.87, green: 0.77, blue: 0.54, alpha: 0.45)
        )
    }

    private static func deskLogTemplate(for label: DailyScoreLabel) -> PosterTemplate {
        let base = standardTemplate(for: label)
        return PosterTemplate(
            backgroundColor: NSColor(calibratedRed: 0.09, green: 0.12, blue: 0.16, alpha: 1),
            cardColor: NSColor(calibratedRed: 0.14, green: 0.17, blue: 0.23, alpha: 1),
            accentColor: base.backgroundColor,
            primaryTextColor: NSColor(calibratedWhite: 0.97, alpha: 1),
            secondaryTextColor: NSColor(calibratedWhite: 0.80, alpha: 1),
            emphasisFillColor: base.accentColor.withAlphaComponent(0.28)
        )
    }
}
