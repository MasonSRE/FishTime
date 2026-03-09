import SwiftUI

struct TodayReportView: View {
    let presentation: DailyReportPresentation?
    let isCompact: Bool
    let selectedTemplate: ReportTemplateStyle
    let onSelectTemplate: (ReportTemplateStyle) -> Void
    let onRefreshVerdict: () -> Void
    let onCopy: () -> Void
    let onSave: () -> Void

    init(
        presentation: DailyReportPresentation?,
        isCompact: Bool = false,
        selectedTemplate: ReportTemplateStyle,
        onSelectTemplate: @escaping (ReportTemplateStyle) -> Void,
        onRefreshVerdict: @escaping () -> Void,
        onCopy: @escaping () -> Void,
        onSave: @escaping () -> Void
    ) {
        self.presentation = presentation
        self.isCompact = isCompact
        self.selectedTemplate = selectedTemplate
        self.onSelectTemplate = onSelectTemplate
        self.onRefreshVerdict = onRefreshVerdict
        self.onCopy = onCopy
        self.onSave = onSave
    }

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 14) {
                if !isCompact {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(AppStrings.Report.templateSectionTitle)
                            .font(.headline)
                        Text(AppStrings.Report.templatePickerHint)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 8) {
                            ForEach(ReportTemplateStyle.allCases, id: \.self) { template in
                                Button {
                                    onSelectTemplate(template)
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: template.iconName)
                                        Text(template.displayName)
                                    }
                                    .font(.subheadline.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 12)
                                }
                                .buttonStyle(.plain)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(selectedTemplate == template ? previewTheme(for: template).accent.opacity(0.20) : Color.secondary.opacity(0.08))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(selectedTemplate == template ? previewTheme(for: template).accent : Color.clear, lineWidth: 1.5)
                                )
                            }
                        }
                    }
                }

                if let presentation {
                    let theme = previewTheme(for: presentation.templateStyle)

                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 8) {
                                Label(presentation.templateStyle.displayName, systemImage: presentation.templateStyle.iconName)
                                    .font(.caption.weight(.bold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(theme.accent.opacity(0.18), in: Capsule())

                                Text(presentation.title)
                                    .font(isCompact ? .headline : .title3.bold())

                                Text(presentation.verdict)
                                    .font(isCompact ? .subheadline.weight(.semibold) : .headline)
                            }

                            Spacer(minLength: 12)

                            if !isCompact {
                                VStack(alignment: .trailing, spacing: 6) {
                                    Text(presentation.laborScoreText)
                                    Text(presentation.moyuScoreText)
                                }
                                .font(.subheadline.weight(.bold))
                            }
                        }

                        Text(presentation.highlight)
                            .font(.callout)
                            .foregroundStyle(theme.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)

                        if isCompact {
                            VStack(alignment: .leading, spacing: 6) {
                                Label(presentation.laborScoreText, systemImage: "bolt.fill")
                                Label(presentation.moyuScoreText, systemImage: "fish.fill")
                            }
                            .font(.caption.weight(.medium))
                        } else {
                            HStack(spacing: 10) {
                                ForEach(Array(presentation.stats.enumerated()), id: \.offset) { _, stat in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(stat.label)
                                            .font(.caption)
                                            .foregroundStyle(theme.secondaryText)
                                        Text(stat.value)
                                            .font(.subheadline.weight(.semibold))
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(10)
                                    .background(theme.cardFill, in: RoundedRectangle(cornerRadius: 12))
                                }
                            }
                        }

                        Text("\(presentation.dateText) · \(AppStrings.App.name)")
                            .font(.caption)
                            .foregroundStyle(theme.secondaryText)

                        HStack(spacing: 12) {
                            Button(AppStrings.Report.refreshVerdict, action: onRefreshVerdict)
                            Button(AppStrings.Report.copyReport, action: onCopy)
                            Button(AppStrings.Report.saveReport, action: onSave)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(isCompact ? 12 : 16)
                    .background(theme.background, in: RoundedRectangle(cornerRadius: isCompact ? 16 : 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: isCompact ? 16 : 20)
                            .stroke(theme.accent.opacity(0.35), lineWidth: 1)
                    )
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(AppStrings.Report.emptyTitle)
                            .font(isCompact ? .headline : .title3.bold())
                        Text(AppStrings.Report.emptySubtitle)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        } label: {
            Text(AppStrings.Report.sectionTitle)
        }
    }

    private func previewTheme(for template: ReportTemplateStyle) -> ReportPreviewTheme {
        switch template {
        case .standard:
            return ReportPreviewTheme(
                background: Color(red: 0.92, green: 0.97, blue: 1.0),
                cardFill: Color(red: 0.76, green: 0.87, blue: 0.97).opacity(0.32),
                accent: Color(red: 0.14, green: 0.36, blue: 0.66),
                secondaryText: Color(red: 0.22, green: 0.35, blue: 0.48)
            )
        case .certificate:
            return ReportPreviewTheme(
                background: Color(red: 0.99, green: 0.95, blue: 0.87),
                cardFill: Color(red: 0.88, green: 0.78, blue: 0.56).opacity(0.28),
                accent: Color(red: 0.62, green: 0.42, blue: 0.14),
                secondaryText: Color(red: 0.43, green: 0.32, blue: 0.18)
            )
        case .deskLog:
            return ReportPreviewTheme(
                background: Color(red: 0.13, green: 0.16, blue: 0.21),
                cardFill: Color(red: 0.21, green: 0.26, blue: 0.33),
                accent: Color(red: 0.49, green: 0.86, blue: 0.65),
                secondaryText: Color(red: 0.79, green: 0.84, blue: 0.89)
            )
        }
    }
}

private struct ReportPreviewTheme {
    let background: Color
    let cardFill: Color
    let accent: Color
    let secondaryText: Color
}
