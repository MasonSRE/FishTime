import Foundation

enum ReportTemplateStyle: String, CaseIterable, Hashable {
    case standard
    case certificate
    case deskLog

    var displayName: String {
        switch self {
        case .standard:
            return AppStrings.Report.standardTemplate
        case .certificate:
            return AppStrings.Report.certificateTemplate
        case .deskLog:
            return AppStrings.Report.deskLogTemplate
        }
    }

    var iconName: String {
        switch self {
        case .standard:
            return "bubble.left.and.text.bubble.right.fill"
        case .certificate:
            return "rosette"
        case .deskLog:
            return "menucard.fill"
        }
    }
}
