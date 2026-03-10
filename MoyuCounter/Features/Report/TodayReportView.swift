import SwiftUI

struct TodayReportView: View {
    let presentation: DailyReportPresentation?
    let periodPresentation: PeriodReportPresentation?
    let isCompact: Bool
    let selectedSurface: ReportSurface
    let selectedPeriodScope: PeriodReportScope
    let selectedTemplate: ReportTemplateStyle
    let onSelectSurface: (ReportSurface) -> Void
    let onSelectPeriodScope: (PeriodReportScope) -> Void
    let onSelectTemplate: (ReportTemplateStyle) -> Void
    let onRefreshVerdict: () -> Void
    let onCopy: () -> Void
    let onSave: () -> Void

    init(
        presentation: DailyReportPresentation?,
        periodPresentation: PeriodReportPresentation?,
        isCompact: Bool = false,
        selectedSurface: ReportSurface,
        selectedPeriodScope: PeriodReportScope,
        selectedTemplate: ReportTemplateStyle,
        onSelectSurface: @escaping (ReportSurface) -> Void,
        onSelectPeriodScope: @escaping (PeriodReportScope) -> Void,
        onSelectTemplate: @escaping (ReportTemplateStyle) -> Void,
        onRefreshVerdict: @escaping () -> Void,
        onCopy: @escaping () -> Void,
        onSave: @escaping () -> Void
    ) {
        self.presentation = presentation
        self.periodPresentation = periodPresentation
        self.isCompact = isCompact
        self.selectedSurface = selectedSurface
        self.selectedPeriodScope = selectedPeriodScope
        self.selectedTemplate = selectedTemplate
        self.onSelectSurface = onSelectSurface
        self.onSelectPeriodScope = onSelectPeriodScope
        self.onSelectTemplate = onSelectTemplate
        self.onRefreshVerdict = onRefreshVerdict
        self.onCopy = onCopy
        self.onSave = onSave
    }

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 14) {
                if !isCompact {
                    pickerSection(
                        title: AppStrings.Report.surfaceSectionTitle,
                        options: ReportSurface.allCases,
                        selected: selectedSurface,
                        label: \.displayName,
                        icon: { $0.iconName },
                        action: onSelectSurface
                    )
                }

                if selectedSurface == .daily {
                    if !isCompact {
                        pickerSection(
                            title: AppStrings.Report.templateSectionTitle,
                            hint: AppStrings.Report.templatePickerHint,
                            options: ReportTemplateStyle.allCases,
                            selected: selectedTemplate,
                            label: \.displayName,
                            icon: { $0.iconName },
                            action: onSelectTemplate
                        )
                    }

                    dailyContent
                } else {
                    if !isCompact {
                        pickerSection(
                            title: AppStrings.Report.periodScopeSectionTitle,
                            options: PeriodReportScope.allCases,
                            selected: selectedPeriodScope,
                            label: \.displayName,
                            icon: { _ in nil },
                            action: onSelectPeriodScope
                        )
                    }

                    periodContent
                }
            }
        } label: {
            Text(AppStrings.Report.sectionTitle)
        }
    }

    @ViewBuilder
    private var dailyContent: some View {
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
            emptyState(title: AppStrings.Report.emptyTitle, subtitle: AppStrings.Report.emptySubtitle)
        }
    }

    @ViewBuilder
    private var periodContent: some View {
        if let periodPresentation {
            VStack(alignment: .leading, spacing: 12) {
                Label(selectedSurface.displayName, systemImage: selectedSurface.iconName)
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(red: 0.80, green: 0.70, blue: 0.50).opacity(0.22), in: Capsule())

                Text(periodPresentation.title)
                    .font(isCompact ? .headline : .title3.bold())

                Text(periodPresentation.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(periodPresentation.verdict)
                    .font(isCompact ? .subheadline.weight(.semibold) : .headline)

                VStack(spacing: 10) {
                    ForEach(Array(periodPresentation.stats.enumerated()), id: \.offset) { _, stat in
                        HStack {
                            Text(stat.label)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(stat.value)
                                .fontWeight(.semibold)
                        }
                        .font(.subheadline)
                        .padding(10)
                        .background(Color(red: 0.95, green: 0.91, blue: 0.84), in: RoundedRectangle(cornerRadius: 12))
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(periodPresentation.highlights.enumerated()), id: \.offset) { _, highlight in
                        Text(highlight)
                            .font(.callout.weight(.medium))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(10)
                            .background(Color(red: 0.90, green: 0.95, blue: 0.98), in: RoundedRectangle(cornerRadius: 12))
                    }
                }

                Text(periodPresentation.footer)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    Button(AppStrings.Report.copyReport, action: onCopy)
                    Button(AppStrings.Report.saveReport, action: onSave)
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(isCompact ? 12 : 16)
            .background(Color(red: 0.99, green: 0.96, blue: 0.90), in: RoundedRectangle(cornerRadius: isCompact ? 16 : 20))
            .overlay(
                RoundedRectangle(cornerRadius: isCompact ? 16 : 20)
                    .stroke(Color(red: 0.73, green: 0.55, blue: 0.23).opacity(0.35), lineWidth: 1)
            )
        } else {
            emptyState(title: AppStrings.Report.periodEmptyTitle, subtitle: AppStrings.Report.periodEmptySubtitle)
        }
    }

    private func emptyState(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(isCompact ? .headline : .title3.bold())
            Text(subtitle)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

    private func pickerSection<Option: Hashable>(
        title: String,
        hint: String? = nil,
        options: [Option],
        selected: Option,
        label: KeyPath<Option, String>,
        icon: @escaping (Option) -> String?,
        action: @escaping (Option) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)

            if let hint {
                Text(hint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                ForEach(options, id: \.self) { option in
                    Button {
                        action(option)
                    } label: {
                        HStack(spacing: 6) {
                            if let iconName = icon(option) {
                                Image(systemName: iconName)
                            }
                            Text(option[keyPath: label])
                        }
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                    }
                    .buttonStyle(.plain)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(selected == option ? Color.accentColor.opacity(0.18) : Color.secondary.opacity(0.08))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(selected == option ? Color.accentColor : Color.clear, lineWidth: 1.5)
                    )
                }
            }
        }
    }
}

private struct ReportPreviewTheme {
    let background: Color
    let cardFill: Color
    let accent: Color
    let secondaryText: Color
}
