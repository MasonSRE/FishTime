import Combine
import Foundation

@MainActor
final class TodayReportViewModel: ObservableObject {
    @Published private(set) var presentation: DailyReportPresentation?
    @Published private(set) var selectedTemplate: ReportTemplateStyle

    private let repository: DailyRecordRepository
    private let settingsStore: SettingsStore
    private let composer: DailyReportComposer

    init(
        repository: DailyRecordRepository,
        settingsStore: SettingsStore,
        composer: DailyReportComposer = DailyReportComposer()
    ) {
        self.repository = repository
        self.settingsStore = settingsStore
        self.composer = composer
        self.selectedTemplate = settingsStore.selectedReportTemplate
        reload()
    }

    func reload() {
        guard let latest = try? repository.fetchLatest() else {
            presentation = nil
            return
        }

        presentation = composer.makePresentation(from: latest, templateStyle: selectedTemplate)
    }

    func refreshVerdict() {
        reload()
    }

    func selectTemplate(_ template: ReportTemplateStyle) {
        guard selectedTemplate != template else { return }
        selectedTemplate = template
        settingsStore.selectedReportTemplate = template
        reload()
    }
}
