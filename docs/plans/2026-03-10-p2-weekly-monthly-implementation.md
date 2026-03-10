# P2 Weekly/Monthly Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add offline weekly/monthly commemorative posters that can be previewed from the main report view and exported from both the main report view and history view.

**Architecture:** Keep daily reports unchanged and build a parallel period-report pipeline: persist surface/scope selection in `SettingsStore`, query `DailyRecord` by date range, aggregate weekly/monthly periods into a dedicated `PeriodReportPresentation`, render those posters with a dedicated renderer, and expose copy/save actions through the existing export service. The main report view switches between daily and period content; history adds lightweight shortcuts for last week and last month.

**Tech Stack:** Swift 6.1, SwiftUI, AppKit, XCTest

---

### Task 1: Persist report surface and period scope selection

**Files:**
- Create: `MoyuCounter/Core/Sharing/ReportSurface.swift`
- Create: `MoyuCounter/Core/Sharing/PeriodReportScope.swift`
- Modify: `MoyuCounter/Core/Settings/SettingsStore.swift`
- Test: `MoyuCounterTests/Settings/SettingsStoreTests.swift`

**Step 1: Write the failing test**

```swift
func test_report_surface_and_period_scope_default_and_persist() {
    let defaults = UserDefaults(suiteName: #function)!
    defaults.removePersistentDomain(forName: #function)

    let store = SettingsStore(userDefaults: defaults)
    XCTAssertEqual(store.selectedReportSurface, .daily)
    XCTAssertEqual(store.selectedPeriodScope, .current)

    store.selectedReportSurface = .monthly
    store.selectedPeriodScope = .previousCompleted

    let reloaded = SettingsStore(userDefaults: defaults)
    XCTAssertEqual(reloaded.selectedReportSurface, .monthly)
    XCTAssertEqual(reloaded.selectedPeriodScope, .previousCompleted)
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter SettingsStoreTests/test_report_surface_and_period_scope_default_and_persist`

Expected: FAIL because `SettingsStore` has no persisted report surface or period scope.

**Step 3: Write minimal implementation**

```swift
enum ReportSurface: String, CaseIterable, Equatable {
    case daily
    case weekly
    case monthly
}

enum PeriodReportScope: String, CaseIterable, Equatable {
    case current
    case previousCompleted
}

@Published var selectedReportSurface: ReportSurface {
    didSet { userDefaults.set(selectedReportSurface.rawValue, forKey: Keys.selectedReportSurface) }
}

@Published var selectedPeriodScope: PeriodReportScope {
    didSet { userDefaults.set(selectedPeriodScope.rawValue, forKey: Keys.selectedPeriodScope) }
}
```

Initialize both properties from `UserDefaults`, defaulting to `.daily` and `.current`.

**Step 4: Run test to verify it passes**

Run: `swift test --filter SettingsStoreTests/test_report_surface_and_period_scope_default_and_persist`

Expected: PASS

**Step 5: Commit**

```bash
git add MoyuCounter/Core/Sharing/ReportSurface.swift MoyuCounter/Core/Sharing/PeriodReportScope.swift MoyuCounter/Core/Settings/SettingsStore.swift MoyuCounterTests/Settings/SettingsStoreTests.swift
git commit -m "feat: persist period report selection"
```

### Task 2: Add date-range fetches and period aggregation

**Files:**
- Create: `MoyuCounter/Core/Sharing/PeriodReportKind.swift`
- Create: `MoyuCounter/Core/Sharing/PeriodReportAggregator.swift`
- Modify: `MoyuCounter/Core/Storage/DailyRecordRepository.swift`
- Test: `MoyuCounterTests/Storage/DailyRecordRepositoryTests.swift`
- Test: `MoyuCounterTests/Sharing/PeriodReportAggregatorTests.swift`

**Step 1: Write the failing tests**

```swift
func test_fetch_records_returns_only_records_inside_date_interval() throws {
    let repository = try DailyRecordRepository.inMemory()
    try repository.save(DailyRecord(date: makeDate(year: 2026, month: 3, day: 2), score: 10, label: "a", activeMinutes: 10))
    try repository.save(DailyRecord(date: makeDate(year: 2026, month: 3, day: 9), score: 20, label: "b", activeMinutes: 20))
    try repository.save(DailyRecord(date: makeDate(year: 2026, month: 3, day: 10), score: 30, label: "c", activeMinutes: 30))

    let interval = DateInterval(start: makeDate(year: 2026, month: 3, day: 9), end: makeDate(year: 2026, month: 3, day: 11))
    let records = try repository.fetchRecords(in: interval)

    XCTAssertEqual(records.map(\.score), [20, 30])
}

func test_aggregator_returns_current_week_snapshot_with_progress_state() throws {
    let repository = try DailyRecordRepository.inMemory()
    try repository.save(DailyRecord(date: makeDate(year: 2026, month: 3, day: 9), score: 65, label: DailyScoreLabel.balancedHuman.rawValue, activeMinutes: 120))
    try repository.save(DailyRecord(date: makeDate(year: 2026, month: 3, day: 10), score: 72, label: DailyScoreLabel.topNiuMa.rawValue, activeMinutes: 180))

    let aggregator = PeriodReportAggregator(
        repository: repository,
        calendar: Self.utcCalendar,
        now: { makeDate(year: 2026, month: 3, day: 10, hour: 20, minute: 0) }
    )

    let snapshot = try aggregator.makeSnapshot(kind: .weekly, scope: .current)

    XCTAssertEqual(snapshot.kind, .weekly)
    XCTAssertEqual(snapshot.scope, .current)
    XCTAssertTrue(snapshot.isInProgress)
    XCTAssertEqual(snapshot.records.count, 2)
    XCTAssertEqual(snapshot.interval.start, makeDate(year: 2026, month: 3, day: 9))
}
```

**Step 2: Run tests to verify they fail**

Run: `swift test --filter DailyRecordRepositoryTests/test_fetch_records_returns_only_records_inside_date_interval`

Expected: FAIL because the repository has no date-interval query.

Run: `swift test --filter PeriodReportAggregatorTests/test_aggregator_returns_current_week_snapshot_with_progress_state`

Expected: FAIL because there is no period aggregator yet.

**Step 3: Write minimal implementation**

```swift
enum PeriodReportKind: Equatable {
    case weekly
    case monthly
}

struct PeriodReportSnapshot: Equatable {
    let kind: PeriodReportKind
    let scope: PeriodReportScope
    let interval: DateInterval
    let records: [DailyRecord]
    let isInProgress: Bool
}

func fetchRecords(in interval: DateInterval) throws -> [DailyRecord] {
    records.filter { interval.contains($0.date) }
}
```

In `PeriodReportAggregator`, calculate natural-week and natural-month boundaries with an injected `Calendar`, trimming `current` periods to `now()` and using full closed periods for `.previousCompleted`.

**Step 4: Run tests to verify they pass**

Run: `swift test --filter DailyRecordRepositoryTests/test_fetch_records_returns_only_records_inside_date_interval`

Expected: PASS

Run: `swift test --filter PeriodReportAggregatorTests/test_aggregator_returns_current_week_snapshot_with_progress_state`

Expected: PASS

**Step 5: Commit**

```bash
git add MoyuCounter/Core/Sharing/PeriodReportKind.swift MoyuCounter/Core/Sharing/PeriodReportAggregator.swift MoyuCounter/Core/Storage/DailyRecordRepository.swift MoyuCounterTests/Storage/DailyRecordRepositoryTests.swift MoyuCounterTests/Sharing/PeriodReportAggregatorTests.swift
git commit -m "feat: add weekly monthly aggregation"
```

### Task 3: Compose and render period report posters

**Files:**
- Create: `MoyuCounter/Core/Sharing/PeriodReportPresentation.swift`
- Create: `MoyuCounter/Core/Sharing/PeriodReportComposer.swift`
- Create: `MoyuCounter/Core/Poster/PeriodPosterRenderer.swift`
- Modify: `MoyuCounter/App/AppStrings.swift`
- Test: `MoyuCounterTests/Sharing/PeriodReportComposerTests.swift`
- Test: `MoyuCounterTests/Poster/PeriodPosterRendererTests.swift`

**Step 1: Write the failing tests**

```swift
func test_composer_builds_monthly_presentation_with_key_stats_and_highlights() {
    let snapshot = PeriodReportSnapshot(
        kind: .monthly,
        scope: .current,
        interval: DateInterval(start: makeDate(year: 2026, month: 3, day: 1), end: makeDate(year: 2026, month: 3, day: 10, hour: 20, minute: 0)),
        records: [
            DailyRecord(date: makeDate(year: 2026, month: 3, day: 3), score: 82, moyuScore: 18, label: DailyScoreLabel.topNiuMa.rawValue, activeMinutes: 300, trackedMinutes: 480, highActivityMinutes: 240, lowActivityMinutes: 40, longestIdleMinutes: 15),
            DailyRecord(date: makeDate(year: 2026, month: 3, day: 6), score: 25, moyuScore: 75, label: DailyScoreLabel.moyuMaster.rawValue, activeMinutes: 40, trackedMinutes: 480, highActivityMinutes: 10, lowActivityMinutes: 320, longestIdleMinutes: 120)
        ],
        isInProgress: true
    )

    let presentation = PeriodReportComposer(calendar: Self.utcCalendar).makePresentation(from: snapshot)

    XCTAssertEqual(presentation.title, "本月摸鱼纪念卡")
    XCTAssertEqual(presentation.stats.count, 4)
    XCTAssertTrue(presentation.subtitle.contains("截至"))
    XCTAssertTrue(presentation.highlights.contains(where: { $0.contains("最拼一天") }))
    XCTAssertTrue(presentation.highlights.contains(where: { $0.contains("最会摸一天") }))
}

func test_period_renderer_returns_png_data() throws {
    let renderer = PeriodPosterRenderer()
    let presentation = PeriodReportPresentation(
        kind: .weekly,
        title: "本周摸鱼纪念卡",
        subtitle: "截至今日",
        verdict: "本周属于人类平衡态",
        stats: [.init(label: "记录天数", value: "4"), .init(label: "平均劳动分", value: "61"), .init(label: "总活跃分钟", value: "820"), .init(label: "最长沉寂分钟", value: "48")],
        highlights: ["最拼一天：周三，劳动分 78", "最会摸一天：周五，摸鱼分 66"],
        footer: "03.03 - 03.09 · 摸鱼统计器"
    )

    let data = try renderer.render(report: presentation)
    XCTAssertEqual(Array(data.prefix(4)), [0x89, 0x50, 0x4E, 0x47])
}
```

**Step 2: Run tests to verify they fail**

Run: `swift test --filter PeriodReportComposerTests/test_composer_builds_monthly_presentation_with_key_stats_and_highlights`

Expected: FAIL because there is no period composer or presentation model.

Run: `swift test --filter PeriodPosterRendererTests/test_period_renderer_returns_png_data`

Expected: FAIL because there is no period renderer.

**Step 3: Write minimal implementation**

```swift
struct PeriodReportPresentation: Equatable {
    let kind: PeriodReportKind
    let title: String
    let subtitle: String
    let verdict: String
    let stats: [DailyReportStat]
    let highlights: [String]
    let footer: String
    let shareText: String
}
```

Have `PeriodReportComposer` derive average score, total active minutes, max idle time, and the two highlight lines from the snapshot. Keep `PeriodPosterRenderer` separate from `PosterRenderer`, but reuse the same image size and AppKit drawing pattern so export behavior stays familiar.

**Step 4: Run tests to verify they pass**

Run: `swift test --filter PeriodReportComposerTests/test_composer_builds_monthly_presentation_with_key_stats_and_highlights`

Expected: PASS

Run: `swift test --filter PeriodPosterRendererTests/test_period_renderer_returns_png_data`

Expected: PASS

**Step 5: Commit**

```bash
git add MoyuCounter/Core/Sharing/PeriodReportPresentation.swift MoyuCounter/Core/Sharing/PeriodReportComposer.swift MoyuCounter/Core/Poster/PeriodPosterRenderer.swift MoyuCounter/App/AppStrings.swift MoyuCounterTests/Sharing/PeriodReportComposerTests.swift MoyuCounterTests/Poster/PeriodPosterRendererTests.swift
git commit -m "feat: add period report rendering"
```

### Task 4: Extend export service for weekly/monthly posters

**Files:**
- Modify: `MoyuCounter/Core/Poster/PosterExportService.swift`
- Modify: `MoyuCounter/App/AppDependencies.swift`
- Test: `MoyuCounterTests/Poster/PosterExportServiceTests.swift`

**Step 1: Write the failing tests**

```swift
func test_generate_and_copy_period_poster_uses_weekly_snapshot_pipeline() throws {
    let repository = try DailyRecordRepository.inMemory()
    try repository.save(DailyRecord(date: makeDate(year: 2026, month: 3, day: 9), score: 68, label: DailyScoreLabel.balancedHuman.rawValue, activeMinutes: 120))

    let periodRenderer = CapturingPeriodPosterRenderer(data: Data([0xAA]))
    let clipboard = StubClipboardWriter()
    let service = PosterExportService(
        repository: repository,
        renderer: StubPosterRenderer(data: Data([0x01])),
        periodRenderer: periodRenderer,
        settingsStore: makeSettingsStore(testName: #function),
        composer: DailyReportComposer(randomIndexProvider: { _, _ in 0 }),
        periodAggregator: PeriodReportAggregator(repository: repository, calendar: Self.utcCalendar, now: { makeDate(year: 2026, month: 3, day: 10, hour: 12, minute: 0) }),
        periodComposer: PeriodReportComposer(calendar: Self.utcCalendar),
        clipboard: clipboard,
        exportDirectory: FileManager.default.temporaryDirectory,
        fileManager: .default
    )

    try service.generateAndCopyPeriodPoster(kind: .weekly, scope: .current)

    XCTAssertEqual(periodRenderer.lastPresentation?.kind, .weekly)
    XCTAssertEqual(clipboard.writtenData, Data([0xAA]))
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter PosterExportServiceTests/test_generate_and_copy_period_poster_uses_weekly_snapshot_pipeline`

Expected: FAIL because the export service has no period-export entry points.

**Step 3: Write minimal implementation**

```swift
protocol PeriodPosterRendering: AnyObject {
    func render(report: PeriodReportPresentation) throws -> Data
}

func generateAndCopyPeriodPoster(kind: PeriodReportKind, scope: PeriodReportScope) throws {
    let snapshot = try periodAggregator.makeSnapshot(kind: kind, scope: scope)
    let presentation = periodComposer.makePresentation(from: snapshot)
    let data = try periodRenderer.render(report: presentation)
    clipboard.writeSharePayload(imageData: data, text: presentation.shareText)
}
```

Mirror the same path for `generateAndSavePeriodPoster(kind:scope:)`. Construct the new dependencies in `AppDependencies` so the main window and history can share the live service.

**Step 4: Run test to verify it passes**

Run: `swift test --filter PosterExportServiceTests/test_generate_and_copy_period_poster_uses_weekly_snapshot_pipeline`

Expected: PASS

**Step 5: Commit**

```bash
git add MoyuCounter/Core/Poster/PosterExportService.swift MoyuCounter/App/AppDependencies.swift MoyuCounterTests/Poster/PosterExportServiceTests.swift
git commit -m "feat: add period poster export service"
```

### Task 5: Switch the main report view between daily and period content

**Files:**
- Modify: `MoyuCounter/Features/Report/TodayReportViewModel.swift`
- Modify: `MoyuCounter/Features/Report/TodayReportView.swift`
- Modify: `MoyuCounter/Features/MainWindow/MainWindowView.swift`
- Modify: `MoyuCounter/App/AppStrings.swift`
- Test: `MoyuCounterTests/Report/TodayReportViewModelTests.swift`

**Step 1: Write the failing tests**

```swift
func test_today_report_view_model_restores_saved_monthly_surface() throws {
    let repository = try DailyRecordRepository.inMemory()
    try repository.save(DailyRecord(date: makeDate(year: 2026, month: 3, day: 9), score: 72, label: DailyScoreLabel.topNiuMa.rawValue, activeMinutes: 180))

    let settings = makeSettingsStore(testName: #function)
    settings.selectedReportSurface = .monthly
    settings.selectedPeriodScope = .previousCompleted

    let viewModel = TodayReportViewModel(
        repository: repository,
        settingsStore: settings,
        composer: DailyReportComposer(randomIndexProvider: { _, _ in 0 }),
        periodAggregator: PeriodReportAggregator(repository: repository, calendar: Self.utcCalendar, now: { makeDate(year: 2026, month: 3, day: 10, hour: 20, minute: 0) }),
        periodComposer: PeriodReportComposer(calendar: Self.utcCalendar)
    )

    XCTAssertEqual(viewModel.selectedSurface, .monthly)
    XCTAssertEqual(viewModel.selectedPeriodScope, .previousCompleted)
    XCTAssertEqual(viewModel.periodPresentation?.kind, .monthly)
}

func test_selecting_weekly_surface_rebuilds_period_presentation_and_persists_state() throws {
    let repository = try DailyRecordRepository.inMemory()
    try repository.save(DailyRecord(date: makeDate(year: 2026, month: 3, day: 10), score: 61, label: DailyScoreLabel.balancedHuman.rawValue, activeMinutes: 140))

    let settings = makeSettingsStore(testName: #function)
    let viewModel = TodayReportViewModel(
        repository: repository,
        settingsStore: settings,
        composer: DailyReportComposer(randomIndexProvider: { _, _ in 0 }),
        periodAggregator: PeriodReportAggregator(repository: repository, calendar: Self.utcCalendar, now: { makeDate(year: 2026, month: 3, day: 10, hour: 20, minute: 0) }),
        periodComposer: PeriodReportComposer(calendar: Self.utcCalendar)
    )

    viewModel.selectSurface(.weekly)
    viewModel.selectPeriodScope(.current)

    XCTAssertEqual(viewModel.selectedSurface, .weekly)
    XCTAssertEqual(settings.selectedReportSurface, .weekly)
    XCTAssertEqual(viewModel.periodPresentation?.kind, .weekly)
}
```

**Step 2: Run tests to verify they fail**

Run: `swift test --filter TodayReportViewModelTests/test_today_report_view_model_restores_saved_monthly_surface`

Expected: FAIL because the view model only knows about daily report state.

Run: `swift test --filter TodayReportViewModelTests/test_selecting_weekly_surface_rebuilds_period_presentation_and_persists_state`

Expected: FAIL because there is no surface/scope API.

**Step 3: Write minimal implementation**

```swift
@Published private(set) var selectedSurface: ReportSurface
@Published private(set) var selectedPeriodScope: PeriodReportScope
@Published private(set) var dailyPresentation: DailyReportPresentation?
@Published private(set) var periodPresentation: PeriodReportPresentation?

func selectSurface(_ surface: ReportSurface) {
    selectedSurface = surface
    settingsStore.selectedReportSurface = surface
    reload()
}

func selectPeriodScope(_ scope: PeriodReportScope) {
    selectedPeriodScope = scope
    settingsStore.selectedPeriodScope = scope
    reload()
}
```

In `TodayReportView`, render the existing daily card when `selectedSurface == .daily`, otherwise render a period card with the same copy/save button row and a separate scope picker. Update `MainWindowView` to route copy/save through `TodayReportViewModel`, not `MenuBarViewModel`, so exports follow the selected surface.

**Step 4: Run tests to verify they pass**

Run: `swift test --filter TodayReportViewModelTests/test_today_report_view_model_restores_saved_monthly_surface`

Expected: PASS

Run: `swift test --filter TodayReportViewModelTests/test_selecting_weekly_surface_rebuilds_period_presentation_and_persists_state`

Expected: PASS

**Step 5: Commit**

```bash
git add MoyuCounter/Features/Report/TodayReportViewModel.swift MoyuCounter/Features/Report/TodayReportView.swift MoyuCounter/Features/MainWindow/MainWindowView.swift MoyuCounter/App/AppStrings.swift MoyuCounterTests/Report/TodayReportViewModelTests.swift
git commit -m "feat: add weekly monthly switching to report view"
```

### Task 6: Add history shortcuts for last week and last month

**Files:**
- Modify: `MoyuCounter/Features/History/HistoryViewModel.swift`
- Modify: `MoyuCounter/Features/History/HistoryView.swift`
- Modify: `MoyuCounter/App/AppStrings.swift`
- Test: `MoyuCounterTests/History/HistoryViewModelTests.swift`

**Step 1: Write the failing tests**

```swift
func test_copy_previous_week_period_report_uses_period_exporter() throws {
    let repository = try DailyRecordRepository.inMemory()
    try repository.save(DailyRecord(date: makeDate(year: 2026, month: 3, day: 3), score: 70, label: DailyScoreLabel.topNiuMa.rawValue, activeMinutes: 180))

    let exporter = StubPosterExporter()
    let viewModel = HistoryViewModel(
        repository: repository,
        composer: DailyReportComposer(randomIndexProvider: { _, _ in 0 }),
        posterExporter: exporter
    )

    viewModel.copyPreviousWeeklyReport()

    XCTAssertEqual(exporter.lastCopiedPeriodKind, .weekly)
    XCTAssertEqual(exporter.lastCopiedPeriodScope, .previousCompleted)
}

func test_copy_previous_month_period_report_uses_period_exporter() throws {
    let repository = try DailyRecordRepository.inMemory()
    try repository.save(DailyRecord(date: makeDate(year: 2026, month: 2, day: 18), score: 22, label: DailyScoreLabel.moyuMaster.rawValue, activeMinutes: 50))

    let exporter = StubPosterExporter()
    let viewModel = HistoryViewModel(
        repository: repository,
        composer: DailyReportComposer(randomIndexProvider: { _, _ in 0 }),
        posterExporter: exporter
    )

    viewModel.copyPreviousMonthlyReport()

    XCTAssertEqual(exporter.lastCopiedPeriodKind, .monthly)
    XCTAssertEqual(exporter.lastCopiedPeriodScope, .previousCompleted)
}
```

**Step 2: Run tests to verify they fail**

Run: `swift test --filter HistoryViewModelTests/test_copy_previous_week_period_report_uses_period_exporter`

Expected: FAIL because history has no weekly/monthly shortcut actions.

Run: `swift test --filter HistoryViewModelTests/test_copy_previous_month_period_report_uses_period_exporter`

Expected: FAIL because history has no weekly/monthly shortcut actions.

**Step 3: Write minimal implementation**

```swift
func copyPreviousWeeklyReport() {
    try? posterExporter?.generateAndCopyPeriodPoster(kind: .weekly, scope: .previousCompleted)
}

func copyPreviousMonthlyReport() {
    try? posterExporter?.generateAndCopyPeriodPoster(kind: .monthly, scope: .previousCompleted)
}
```

Expose two buttons at the top of `HistoryView`:

```swift
Button(AppStrings.Report.copyPreviousWeeklyReport) {
    viewModel.copyPreviousWeeklyReport()
}

Button(AppStrings.Report.copyPreviousMonthlyReport) {
    viewModel.copyPreviousMonthlyReport()
}
```

**Step 4: Run tests to verify they pass**

Run: `swift test --filter HistoryViewModelTests/test_copy_previous_week_period_report_uses_period_exporter`

Expected: PASS

Run: `swift test --filter HistoryViewModelTests/test_copy_previous_month_period_report_uses_period_exporter`

Expected: PASS

**Step 5: Commit**

```bash
git add MoyuCounter/Features/History/HistoryViewModel.swift MoyuCounter/Features/History/HistoryView.swift MoyuCounter/App/AppStrings.swift MoyuCounterTests/History/HistoryViewModelTests.swift
git commit -m "feat: add history period poster shortcuts"
```

### Final verification

After Task 6, run the full suite before any merge or review:

```bash
swift test
```

Expected: `40+ tests, 0 failures` with the new period-report coverage added on top of the current baseline.
