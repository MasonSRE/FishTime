import SwiftUI

struct TodayReportView: View {
    let presentation: DailyReportPresentation?
    let isCompact: Bool
    let onRefreshVerdict: () -> Void
    let onCopy: () -> Void
    let onSave: () -> Void

    init(
        presentation: DailyReportPresentation?,
        isCompact: Bool = false,
        onRefreshVerdict: @escaping () -> Void,
        onCopy: @escaping () -> Void,
        onSave: @escaping () -> Void
    ) {
        self.presentation = presentation
        self.isCompact = isCompact
        self.onRefreshVerdict = onRefreshVerdict
        self.onCopy = onCopy
        self.onSave = onSave
    }

    var body: some View {
        GroupBox {
            if let presentation {
                VStack(alignment: .leading, spacing: 10) {
                    Text(presentation.title)
                        .font(isCompact ? .headline : .title3.bold())

                    Text(presentation.verdict)
                        .font(isCompact ? .subheadline.weight(.semibold) : .headline)

                    Text(presentation.highlight)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 12) {
                        Label(presentation.laborScoreText, systemImage: "bolt.fill")
                        Label(presentation.moyuScoreText, systemImage: "fish.fill")
                    }
                    .font(.caption.weight(.medium))

                    if !isCompact {
                        HStack(spacing: 10) {
                            ForEach(Array(presentation.stats.enumerated()), id: \.offset) { _, stat in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(stat.label)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(stat.value)
                                        .font(.subheadline.weight(.semibold))
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(10)
                                .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }

                    HStack(spacing: 12) {
                        Button(AppStrings.Report.refreshVerdict, action: onRefreshVerdict)
                        Button(AppStrings.Report.copyReport, action: onCopy)
                        Button(AppStrings.Report.saveReport, action: onSave)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
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
        } label: {
            Text(AppStrings.Report.sectionTitle)
        }
    }
}
