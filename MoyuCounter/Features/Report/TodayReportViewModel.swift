import Combine
import Foundation

@MainActor
final class TodayReportViewModel: ObservableObject {
    @Published private(set) var presentation: DailyReportPresentation?
    @Published private(set) var periodPresentation: PeriodReportPresentation?
    @Published private(set) var selectedTemplate: ReportTemplateStyle
    @Published private(set) var selectedSurface: ReportSurface
    @Published private(set) var selectedPeriodScope: PeriodReportScope

    private let repository: DailyRecordRepository
    private let settingsStore: SettingsStore
    private let composer: DailyReportComposer
    private let periodAggregator: PeriodReportAggregator
    private let periodComposer: PeriodReportComposer
    private let posterExporter: PosterExporting?

    init(
        repository: DailyRecordRepository,
        settingsStore: SettingsStore,
        composer: DailyReportComposer = DailyReportComposer(),
        periodAggregator: PeriodReportAggregator? = nil,
        periodComposer: PeriodReportComposer = PeriodReportComposer(),
        posterExporter: PosterExporting? = nil
    ) {
        self.repository = repository
        self.settingsStore = settingsStore
        self.composer = composer
        self.periodAggregator = periodAggregator ?? PeriodReportAggregator(repository: repository)
        self.periodComposer = periodComposer
        self.posterExporter = posterExporter
        self.selectedTemplate = settingsStore.selectedReportTemplate
        self.selectedSurface = settingsStore.selectedReportSurface
        self.selectedPeriodScope = settingsStore.selectedPeriodScope
        reload()
    }

    func reload() {
        reloadDailyPresentation()
        reloadPeriodPresentation()
    }

    func refreshVerdict() {
        guard selectedSurface == .daily else { return }
        reloadDailyPresentation()
    }

    func selectTemplate(_ template: ReportTemplateStyle) {
        guard selectedTemplate != template else { return }
        selectedTemplate = template
        settingsStore.selectedReportTemplate = template
        reloadDailyPresentation()
    }

    func selectSurface(_ surface: ReportSurface) {
        guard selectedSurface != surface else { return }
        selectedSurface = surface
        settingsStore.selectedReportSurface = surface
        reload()
    }

    func selectPeriodScope(_ scope: PeriodReportScope) {
        guard selectedPeriodScope != scope else { return }
        selectedPeriodScope = scope
        settingsStore.selectedPeriodScope = scope
        reloadPeriodPresentation()
    }

    func copyCurrentReportToClipboard() {
        guard let posterExporter else { return }

        do {
            switch selectedSurface {
            case .daily:
                try posterExporter.generateAndCopyLatestPoster()
            case .weekly:
                try posterExporter.generateAndCopyPeriodPoster(kind: .weekly, scope: selectedPeriodScope)
            case .monthly:
                try posterExporter.generateAndCopyPeriodPoster(kind: .monthly, scope: selectedPeriodScope)
            }
        } catch {}
    }

    func saveCurrentReport() {
        guard let posterExporter else { return }

        do {
            switch selectedSurface {
            case .daily:
                _ = try posterExporter.generateAndSaveLatestPoster()
            case .weekly:
                _ = try posterExporter.generateAndSavePeriodPoster(kind: .weekly, scope: selectedPeriodScope)
            case .monthly:
                _ = try posterExporter.generateAndSavePeriodPoster(kind: .monthly, scope: selectedPeriodScope)
            }
        } catch {}
    }

    private func reloadDailyPresentation() {
        guard let latest = try? repository.fetchLatest() else {
            presentation = nil
            return
        }

        presentation = composer.makePresentation(from: latest, templateStyle: selectedTemplate)
    }

    private func reloadPeriodPresentation() {
        guard let kind = selectedSurface.periodKind else {
            periodPresentation = nil
            return
        }

        guard let snapshot = try? periodAggregator.makeSnapshot(kind: kind, scope: selectedPeriodScope),
              !snapshot.records.isEmpty else {
            periodPresentation = nil
            return
        }

        periodPresentation = periodComposer.makePresentation(from: snapshot)
    }
}

private extension ReportSurface {
    var periodKind: PeriodReportKind? {
        switch self {
        case .daily:
            return nil
        case .weekly:
            return .weekly
        case .monthly:
            return .monthly
        }
    }
}
