# P2 Template System Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add three switchable report templates to today's report, remember the selected template, and keep preview, copy, save, and history re-share on the same template path.

**Architecture:** Introduce a small `ReportTemplateStyle` domain type persisted in `SettingsStore`, thread the selected style through `DailyReportComposer` and `PosterRenderer`, and keep `PosterExportService` as the single source of truth for generated share payloads. UI changes stay in the today report flow; settlement data and `DailyRecord` storage remain unchanged.

**Tech Stack:** Swift 6.1, SwiftUI, AppKit, XCTest

---

### Task 1: Add a persistent report template preference

**Files:**
- Create: `MoyuCounter/Core/Poster/ReportTemplateStyle.swift`
- Modify: `MoyuCounter/Core/Settings/SettingsStore.swift`
- Test: `MoyuCounterTests/Settings/SettingsStoreTests.swift`

**Step 1: Write the failing test**

```swift
func test_selected_report_template_defaults_to_standard_and_persists() {
    let defaults = UserDefaults(suiteName: #function)!
    defaults.removePersistentDomain(forName: #function)

    let store = SettingsStore(userDefaults: defaults)
    XCTAssertEqual(store.selectedReportTemplate, .standard)

    store.selectedReportTemplate = .certificate

    let reloaded = SettingsStore(userDefaults: defaults)
    XCTAssertEqual(reloaded.selectedReportTemplate, .certificate)
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter SettingsStoreTests/test_selected_report_template_defaults_to_standard_and_persists`
Expected: FAIL because `SettingsStore` has no template preference yet.

**Step 3: Write minimal implementation**

```swift
enum ReportTemplateStyle: String, CaseIterable, Equatable {
    case standard
    case certificate
    case deskLog
}

@Published var selectedReportTemplate: ReportTemplateStyle {
    didSet {
        userDefaults.set(selectedReportTemplate.rawValue, forKey: Keys.selectedReportTemplate)
    }
}
```

Initialize `selectedReportTemplate` from `UserDefaults`, defaulting to `.standard`.

**Step 4: Run test to verify it passes**

Run: `swift test --filter SettingsStoreTests/test_selected_report_template_defaults_to_standard_and_persists`
Expected: PASS

**Step 5: Commit**

```bash
git add MoyuCounter/Core/Poster/ReportTemplateStyle.swift MoyuCounter/Core/Settings/SettingsStore.swift MoyuCounterTests/Settings/SettingsStoreTests.swift
git commit -m "feat: persist selected report template"
```

### Task 2: Thread template style through report composition and rendering

**Files:**
- Modify: `MoyuCounter/Core/Sharing/DailyReportPresentation.swift`
- Modify: `MoyuCounter/Core/Sharing/DailyReportComposer.swift`
- Modify: `MoyuCounter/Core/Poster/PosterTemplate.swift`
- Modify: `MoyuCounter/Core/Poster/PosterRenderer.swift`
- Test: `MoyuCounterTests/Sharing/DailyReportComposerTests.swift`
- Test: `MoyuCounterTests/Poster/PosterRendererTests.swift`

**Step 1: Write the failing tests**

```swift
func test_composer_keeps_scores_stable_across_templates_but_changes_template_specific_copy() {
    let composer = DailyReportComposer(randomIndexProvider: { _, _ in 0 })
    let record = DailyRecord(
        date: Date(timeIntervalSince1970: 86_400),
        score: 55,
        moyuScore: 45,
        label: DailyScoreLabel.balancedHuman.rawValue,
        activeMinutes: 180,
        trackedMinutes: 480,
        highActivityMinutes: 120,
        lowActivityMinutes: 120,
        longestIdleMinutes: 18
    )

    let standard = composer.makePresentation(from: record, templateStyle: .standard)
    let certificate = composer.makePresentation(from: record, templateStyle: .certificate)

    XCTAssertEqual(standard.laborScoreText, certificate.laborScoreText)
    XCTAssertEqual(standard.moyuScoreText, certificate.moyuScoreText)
    XCTAssertNotEqual(standard.shareText, certificate.shareText)
    XCTAssertEqual(certificate.templateStyle, .certificate)
}

func test_renderer_returns_png_data_for_every_template() throws {
    let renderer = PosterRenderer()

    for style in ReportTemplateStyle.allCases {
        let report = DailyReportPresentation(
            label: .moyuMaster,
            templateStyle: style,
            title: "摸鱼大师",
            laborScoreText: "劳动分 30",
            moyuScoreText: "摸鱼分 70",
            verdict: "Fish mode",
            highlight: "连续 120 分钟低活跃，堪称隐身办公。",
            stats: [
                .init(label: "活跃分钟", value: "40"),
                .init(label: "最长沉寂", value: "120 分钟"),
                .init(label: "统计范围", value: "480 分钟"),
            ],
            dateText: "2026年3月9日",
            shareText: "摸鱼大师 | 劳动分 30 · 摸鱼分 70"
        )

        let data = try renderer.render(report: report)
        XCTAssertEqual(Array(data.prefix(4)), [0x89, 0x50, 0x4E, 0x47])
    }
}
```

**Step 2: Run tests to verify they fail**

Run: `swift test --filter DailyReportComposerTests/test_composer_keeps_scores_stable_across_templates_but_changes_template_specific_copy`
Expected: FAIL because `makePresentation` does not accept a template style.

Run: `swift test --filter PosterRendererTests/test_renderer_returns_png_data_for_every_template`
Expected: FAIL because `DailyReportPresentation` has no template style and renderer is single-layout only.

**Step 3: Write minimal implementation**

```swift
struct DailyReportPresentation: Equatable {
    let label: DailyScoreLabel
    let templateStyle: ReportTemplateStyle
    // existing fields...
}

func makePresentation(from record: DailyRecord, templateStyle: ReportTemplateStyle) -> DailyReportPresentation {
    let stats = stats(for: record, templateStyle: templateStyle)
    return DailyReportPresentation(
        label: label,
        templateStyle: templateStyle,
        // existing fields...
    )
}
```

In `PosterRenderer`, switch on `report.templateStyle` and delegate to three private rendering functions while reusing shared drawing helpers.

**Step 4: Run tests to verify they pass**

Run: `swift test --filter DailyReportComposerTests/test_composer_keeps_scores_stable_across_templates_but_changes_template_specific_copy`
Expected: PASS

Run: `swift test --filter PosterRendererTests/test_renderer_returns_png_data_for_every_template`
Expected: PASS

**Step 5: Commit**

```bash
git add MoyuCounter/Core/Sharing/DailyReportPresentation.swift MoyuCounter/Core/Sharing/DailyReportComposer.swift MoyuCounter/Core/Poster/PosterTemplate.swift MoyuCounter/Core/Poster/PosterRenderer.swift MoyuCounterTests/Sharing/DailyReportComposerTests.swift MoyuCounterTests/Poster/PosterRendererTests.swift
git commit -m "feat: add multi-template report rendering"
```

### Task 3: Add template switching to today's report flow

**Files:**
- Modify: `MoyuCounter/Features/Report/TodayReportViewModel.swift`
- Modify: `MoyuCounter/Features/Report/TodayReportView.swift`
- Modify: `MoyuCounter/Features/MainWindow/MainWindowView.swift`
- Modify: `MoyuCounter/App/AppDependencies.swift`
- Modify: `MoyuCounter/App/AppStrings.swift`
- Test: `MoyuCounterTests/Report/TodayReportViewModelTests.swift`

**Step 1: Write the failing tests**

```swift
@MainActor
func test_today_report_view_model_uses_saved_template_on_load() throws {
    let repository = try DailyRecordRepository.inMemory()
    try repository.save(
        DailyRecord(
            date: Date(),
            score: 66,
            moyuScore: 34,
            label: DailyScoreLabel.balancedHuman.rawValue,
            activeMinutes: 150,
            trackedMinutes: 480,
            highActivityMinutes: 120,
            lowActivityMinutes: 100,
            longestIdleMinutes: 24
        )
    )

    let defaults = UserDefaults(suiteName: #function)!
    defaults.removePersistentDomain(forName: #function)
    let settings = SettingsStore(userDefaults: defaults)
    settings.selectedReportTemplate = .deskLog

    let viewModel = TodayReportViewModel(
        repository: repository,
        settingsStore: settings,
        composer: DailyReportComposer(randomIndexProvider: { _, _ in 0 })
    )

    XCTAssertEqual(viewModel.presentation?.templateStyle, .deskLog)
}

@MainActor
func test_select_template_updates_presentation_and_persists_selection() throws {
    // create repository and record...
    let settings = SettingsStore(userDefaults: UserDefaults(suiteName: #function)!)
    let viewModel = TodayReportViewModel(
        repository: repository,
        settingsStore: settings,
        composer: DailyReportComposer(randomIndexProvider: { _, _ in 0 })
    )

    viewModel.selectTemplate(.certificate)

    XCTAssertEqual(viewModel.presentation?.templateStyle, .certificate)
    XCTAssertEqual(settings.selectedReportTemplate, .certificate)
}
```

**Step 2: Run tests to verify they fail**

Run: `swift test --filter TodayReportViewModelTests/test_today_report_view_model_uses_saved_template_on_load`
Expected: FAIL because the view model does not read a settings-backed template.

Run: `swift test --filter TodayReportViewModelTests/test_select_template_updates_presentation_and_persists_selection`
Expected: FAIL because there is no template selection API.

**Step 3: Write minimal implementation**

```swift
@Published private(set) var selectedTemplate: ReportTemplateStyle

init(
    repository: DailyRecordRepository,
    settingsStore: SettingsStore,
    composer: DailyReportComposer = DailyReportComposer()
) {
    self.selectedTemplate = settingsStore.selectedReportTemplate
    // existing setup...
}

func selectTemplate(_ template: ReportTemplateStyle) {
    selectedTemplate = template
    settingsStore.selectedReportTemplate = template
    reload()
}
```

Update `TodayReportView` to render a small template picker above the preview and wire it through `MainWindowView`.

**Step 4: Run tests to verify they pass**

Run: `swift test --filter TodayReportViewModelTests/test_today_report_view_model_uses_saved_template_on_load`
Expected: PASS

Run: `swift test --filter TodayReportViewModelTests/test_select_template_updates_presentation_and_persists_selection`
Expected: PASS

**Step 5: Commit**

```bash
git add MoyuCounter/Features/Report/TodayReportViewModel.swift MoyuCounter/Features/Report/TodayReportView.swift MoyuCounter/Features/MainWindow/MainWindowView.swift MoyuCounter/App/AppDependencies.swift MoyuCounter/App/AppStrings.swift MoyuCounterTests/Report/TodayReportViewModelTests.swift
git commit -m "feat: add template switching to today's report"
```

### Task 4: Keep copy, save, menu bar, and history re-share on the selected template

**Files:**
- Modify: `MoyuCounter/Core/Poster/PosterExportService.swift`
- Modify: `MoyuCounter/Features/History/HistoryViewModel.swift`
- Modify: `MoyuCounter/Features/MenuBar/MenuBarViewModel.swift`
- Modify: `MoyuCounter/App/AppDependencies.swift`
- Test: `MoyuCounterTests/Poster/PosterExportServiceTests.swift`
- Test: `MoyuCounterTests/History/HistoryViewModelTests.swift`

**Step 1: Write the failing tests**

```swift
func test_export_service_renders_latest_report_using_selected_template() throws {
    let repository = try DailyRecordRepository.inMemory()
    try repository.save(
        DailyRecord(
            date: Date(timeIntervalSince1970: 86_400),
            score: 55,
            moyuScore: 45,
            label: DailyScoreLabel.balancedHuman.rawValue,
            activeMinutes: 180,
            trackedMinutes: 480,
            highActivityMinutes: 120,
            lowActivityMinutes: 120,
            longestIdleMinutes: 18
        )
    )

    let defaults = UserDefaults(suiteName: #function)!
    defaults.removePersistentDomain(forName: #function)
    let settings = SettingsStore(userDefaults: defaults)
    settings.selectedReportTemplate = .deskLog
    let renderer = CapturingRenderer()

    let service = PosterExportService(
        repository: repository,
        renderer: renderer,
        settingsStore: settings,
        clipboard: CapturingClipboard(),
        exportDirectory: URL(fileURLWithPath: NSTemporaryDirectory()),
        fileManager: .default
    )

    try service.generateAndCopyLatestPoster()

    XCTAssertEqual(renderer.renderedTemplateStyles, [.deskLog])
}

func test_copy_report_for_row_uses_current_template_selection() throws {
    // save one record...
    let defaults = UserDefaults(suiteName: #function)!
    defaults.removePersistentDomain(forName: #function)
    let settings = SettingsStore(userDefaults: defaults)
    settings.selectedReportTemplate = .certificate
    let exporter = CapturingPosterExporter()

    let viewModel = HistoryViewModel(
        repository: repository,
        settingsStore: settings,
        composer: DailyReportComposer(randomIndexProvider: { _, _ in 0 }),
        posterExporter: exporter
    )

    let row = try XCTUnwrap(viewModel.records.first)
    viewModel.copyReport(for: row)

    XCTAssertEqual(exporter.copiedTemplateStyles, [.certificate])
}
```

**Step 2: Run tests to verify they fail**

Run: `swift test --filter PosterExportServiceTests/test_export_service_renders_latest_report_using_selected_template`
Expected: FAIL because the export service does not know about settings-backed template selection.

Run: `swift test --filter HistoryViewModelTests/test_copy_report_for_row_uses_current_template_selection`
Expected: FAIL because history re-share does not carry template state yet.

**Step 3: Write minimal implementation**

```swift
final class PosterExportService: PosterExporting {
    private let settingsStore: SettingsStore

    private func render(record: DailyRecord) throws -> RenderedReportPayload {
        let report = composer.makePresentation(
            from: record,
            templateStyle: settingsStore.selectedReportTemplate
        )
        let data = try renderer.render(report: report)
        return RenderedReportPayload(data: data, report: report)
    }
}
```

Update live dependency construction so both `MenuBarViewModel` and `HistoryViewModel` reuse the same exporter instance that already has the shared `SettingsStore`.

**Step 4: Run tests to verify they pass**

Run: `swift test --filter PosterExportServiceTests/test_export_service_renders_latest_report_using_selected_template`
Expected: PASS

Run: `swift test --filter HistoryViewModelTests/test_copy_report_for_row_uses_current_template_selection`
Expected: PASS

**Step 5: Commit**

```bash
git add MoyuCounter/Core/Poster/PosterExportService.swift MoyuCounter/Features/History/HistoryViewModel.swift MoyuCounter/Features/MenuBar/MenuBarViewModel.swift MoyuCounter/App/AppDependencies.swift MoyuCounterTests/Poster/PosterExportServiceTests.swift MoyuCounterTests/History/HistoryViewModelTests.swift
git commit -m "feat: keep report exports aligned with selected template"
```

### Task 5: Run full verification and clean up

**Files:**
- Verify only

**Step 1: Run focused regression tests**

Run: `swift test --filter SettingsStoreTests`
Expected: PASS

Run: `swift test --filter DailyReportComposerTests`
Expected: PASS

Run: `swift test --filter PosterRendererTests`
Expected: PASS

Run: `swift test --filter TodayReportViewModelTests`
Expected: PASS

Run: `swift test --filter HistoryViewModelTests`
Expected: PASS

Run: `swift test --filter PosterExportServiceTests`
Expected: PASS

**Step 2: Run the full suite**

Run: `swift test`
Expected: PASS with the full project test count and `0 failures`

**Step 3: Inspect the worktree state**

Run: `git status --short`
Expected: no unexpected modified files

**Step 4: Commit the verification checkpoint**

```bash
git add -A
git commit -m "test: verify p2 template system flow"
```
