# Daily Group Battle Report Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a share-first daily battle report flow that generates group-friendly report cards, richer daily records, and quick re-share entry points in the macOS app.

**Architecture:** Extend the existing settlement pipeline so it persists share-ready activity metrics, then compose a presentation model with randomized verdict copy and highlight text for both the poster renderer and UI surfaces. Keep the implementation fully offline by using deterministic score data, local copy pools, and SwiftUI/AppKit views wired through the current dependency container.

**Tech Stack:** Swift 6.1, SwiftUI, AppKit, XCTest

---

> Current workspace note: this directory does not currently appear to be a Git repository. The commit steps below assume the project will be initialized in Git before execution; otherwise skip the commit step or initialize Git first.

### Task 1: Extend score output with report-ready metrics

**Files:**
- Modify: `MoyuCounter/Core/Scoring/DailyScoreResult.swift`
- Modify: `MoyuCounter/Core/Scoring/DailyScoreCalculator.swift`
- Test: `MoyuCounterTests/Scoring/DailyScoreCalculatorTests.swift`

**Step 1: Write the failing test**

```swift
func test_calculator_returns_activity_breakdown_for_report_generation() {
    let calculator = DailyScoreCalculator()

    let result = calculator.calculate(from: [
        .init(epm: 1, minutes: 2),
        .init(epm: 20, minutes: 3)
    ])

    XCTAssertEqual(result.trackedMinutes, 5)
    XCTAssertEqual(result.lowActivityMinutes, 2)
    XCTAssertEqual(result.highActivityMinutes, 3)
    XCTAssertEqual(result.longestIdleMinutes, 2)
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter DailyScoreCalculatorTests/test_calculator_returns_activity_breakdown_for_report_generation`
Expected: FAIL because the new stored properties do not exist on `DailyScoreResult`.

**Step 3: Write minimal implementation**

```swift
struct DailyScoreResult {
    let laborScore: Int
    let moyuScore: Int
    let label: DailyScoreLabel
    let oneLiner: String
    let trackedMinutes: Int
    let lowActivityMinutes: Int
    let highActivityMinutes: Int
    let longestIdleMinutes: Int
}
```

Update `DailyScoreCalculator.calculate(from:)` to fill those fields from the existing sample loop.

**Step 4: Run test to verify it passes**

Run: `swift test --filter DailyScoreCalculatorTests/test_calculator_returns_activity_breakdown_for_report_generation`
Expected: PASS

**Step 5: Commit**

```bash
git add MoyuCounter/Core/Scoring/DailyScoreResult.swift MoyuCounter/Core/Scoring/DailyScoreCalculator.swift MoyuCounterTests/Scoring/DailyScoreCalculatorTests.swift
git commit -m "feat: expose share-ready scoring metrics"
```

### Task 2: Persist share-ready daily record fields during settlement

**Files:**
- Modify: `MoyuCounter/Core/Storage/DailyRecord.swift`
- Modify: `MoyuCounter/Core/Settlement/DailySettlementService.swift`
- Modify: `MoyuCounter/Core/Storage/DailyRecordRepository.swift`
- Test: `MoyuCounterTests/Settlement/DailySettlementServiceTests.swift`
- Test: `MoyuCounterTests/Storage/DailyRecordRepositoryTests.swift`

**Step 1: Write the failing test**

```swift
func test_settlement_saves_report_metrics_for_later_sharing() throws {
    let aggregator = MinuteBucketAggregator()
    aggregator.record(timestamp: Date(timeIntervalSince1970: 0))
    aggregator.record(timestamp: Date(timeIntervalSince1970: 65))

    let repository = try DailyRecordRepository.inMemory()
    let service = DailySettlementService(
        aggregator: aggregator,
        windowProvider: StubTrackingWindowProvider(range: 0...1),
        calculator: DailyScoreCalculator(),
        repository: repository,
        notifier: CapturingNotifier()
    )

    let saved = try service.settle(for: Date(timeIntervalSince1970: 120))

    XCTAssertEqual(saved.moyuScore, 100 - saved.score)
    XCTAssertEqual(saved.trackedMinutes, 2)
    XCTAssertEqual(saved.activeMinutes, 2)
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter DailySettlementServiceTests/test_settlement_saves_report_metrics_for_later_sharing`
Expected: FAIL because `DailyRecord` does not yet carry the share-ready fields.

**Step 3: Write minimal implementation**

```swift
struct DailyRecord: Codable, Equatable {
    let date: Date
    let score: Int
    let moyuScore: Int
    let label: String
    let activeMinutes: Int
    let trackedMinutes: Int
    let highActivityMinutes: Int
    let lowActivityMinutes: Int
    let longestIdleMinutes: Int
}
```

Update `DailySettlementService` to map the enriched `DailyScoreResult` into the new stored record fields. Update repository tests and fixtures so persistence still encodes and decodes correctly.

**Step 4: Run test to verify it passes**

Run: `swift test --filter DailySettlementServiceTests/test_settlement_saves_report_metrics_for_later_sharing`
Expected: PASS

**Step 5: Commit**

```bash
git add MoyuCounter/Core/Storage/DailyRecord.swift MoyuCounter/Core/Settlement/DailySettlementService.swift MoyuCounter/Core/Storage/DailyRecordRepository.swift MoyuCounterTests/Settlement/DailySettlementServiceTests.swift MoyuCounterTests/Storage/DailyRecordRepositoryTests.swift
git commit -m "feat: persist daily report metrics"
```

### Task 3: Add randomized verdict copy and highlight generation

**Files:**
- Create: `MoyuCounter/Core/Sharing/DailyReportPresentation.swift`
- Create: `MoyuCounter/Core/Sharing/DailyReportComposer.swift`
- Create: `MoyuCounter/Core/Sharing/VerdictCopyLibrary.swift`
- Test: `MoyuCounterTests/Sharing/DailyReportComposerTests.swift`

**Step 1: Write the failing test**

```swift
func test_composer_builds_group_share_presentation_for_moyu_record() {
    let composer = DailyReportComposer(randomIndexProvider: { _, count in count - 1 })
    let record = DailyRecord(
        date: Date(timeIntervalSince1970: 86_400),
        score: 32,
        moyuScore: 68,
        label: DailyScoreLabel.moyuMaster.rawValue,
        activeMinutes: 40,
        trackedMinutes: 480,
        highActivityMinutes: 12,
        lowActivityMinutes: 300,
        longestIdleMinutes: 96
    )

    let presentation = composer.makePresentation(from: record)

    XCTAssertEqual(presentation.title, "摸鱼大师")
    XCTAssertFalse(presentation.verdict.isEmpty)
    XCTAssertTrue(presentation.highlight.contains("96"))
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter DailyReportComposerTests/test_composer_builds_group_share_presentation_for_moyu_record`
Expected: FAIL because the sharing module does not exist.

**Step 3: Write minimal implementation**

```swift
struct DailyReportPresentation {
    let title: String
    let laborScoreText: String
    let moyuScoreText: String
    let verdict: String
    let highlight: String
    let stats: [String]
}
```

Implement `DailyReportComposer` so it:
- maps stored labels to report titles,
- selects verdict copy from `VerdictCopyLibrary`,
- derives one highlight string from the record metrics.

**Step 4: Run test to verify it passes**

Run: `swift test --filter DailyReportComposerTests/test_composer_builds_group_share_presentation_for_moyu_record`
Expected: PASS

**Step 5: Commit**

```bash
git add MoyuCounter/Core/Sharing/DailyReportPresentation.swift MoyuCounter/Core/Sharing/DailyReportComposer.swift MoyuCounter/Core/Sharing/VerdictCopyLibrary.swift MoyuCounterTests/Sharing/DailyReportComposerTests.swift
git commit -m "feat: compose shareable daily report copy"
```

### Task 4: Upgrade poster export to render battle report cards

**Files:**
- Modify: `MoyuCounter/Core/Poster/PosterTemplate.swift`
- Modify: `MoyuCounter/Core/Poster/PosterRenderer.swift`
- Modify: `MoyuCounter/Core/Poster/PosterExportService.swift`
- Modify: `MoyuCounterTests/Poster/PosterRendererTests.swift`
- Modify: `MoyuCounterTests/Poster/PosterExportServiceTests.swift`

**Step 1: Write the failing test**

```swift
func test_generate_and_copy_latest_poster_renders_report_presentation() throws {
    let repository = try DailyRecordRepository.inMemory()
    try repository.save(
        DailyRecord(
            date: Date(),
            score: 80,
            moyuScore: 20,
            label: DailyScoreLabel.topNiuMa.rawValue,
            activeMinutes: 300,
            trackedMinutes: 480,
            highActivityMinutes: 280,
            lowActivityMinutes: 40,
            longestIdleMinutes: 12
        )
    )

    let renderer = CapturingPosterRenderer(data: Data([0xAA]))
    let service = PosterExportService(
        repository: repository,
        renderer: renderer,
        clipboard: StubClipboardWriter(),
        exportDirectory: FileManager.default.temporaryDirectory,
        fileManager: .default
    )

    try service.generateAndCopyLatestPoster()

    XCTAssertEqual(renderer.lastPresentation?.title, "顶级牛马")
    XCTAssertFalse(renderer.lastPresentation?.highlight.isEmpty ?? true)
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter PosterExportServiceTests/test_generate_and_copy_latest_poster_renders_report_presentation`
Expected: FAIL because `PosterExportService` still renders directly from `DailyScoreResult`.

**Step 3: Write minimal implementation**

```swift
protocol PosterRendering: AnyObject {
    func render(report: DailyReportPresentation) throws -> Data
}
```

Update `PosterExportService` to use `DailyReportComposer`, build a `DailyReportPresentation`, and render the richer poster layout. Update `PosterRenderer` to draw the new information hierarchy: title, main score, verdict, highlight, and stat rows.

**Step 4: Run test to verify it passes**

Run: `swift test --filter PosterExportServiceTests/test_generate_and_copy_latest_poster_renders_report_presentation`
Expected: PASS

**Step 5: Commit**

```bash
git add MoyuCounter/Core/Poster/PosterTemplate.swift MoyuCounter/Core/Poster/PosterRenderer.swift MoyuCounter/Core/Poster/PosterExportService.swift MoyuCounterTests/Poster/PosterRendererTests.swift MoyuCounterTests/Poster/PosterExportServiceTests.swift
git commit -m "feat: render share-first daily battle report cards"
```

### Task 5: Surface today's report in the main window and menu bar

**Files:**
- Create: `MoyuCounter/Features/Report/TodayReportView.swift`
- Create: `MoyuCounter/Features/Report/TodayReportViewModel.swift`
- Modify: `MoyuCounter/App/AppDependencies.swift`
- Modify: `MoyuCounter/Features/MainWindow/MainWindowView.swift`
- Modify: `MoyuCounter/Features/MenuBar/MenuBarRootView.swift`
- Modify: `MoyuCounter/Features/MenuBar/MenuBarViewModel.swift`
- Modify: `MoyuCounter/App/AppStrings.swift`
- Test: `MoyuCounterTests/Report/TodayReportViewModelTests.swift`
- Modify: `MoyuCounterTests/MenuBar/MenuBarViewModelTests.swift`

**Step 1: Write the failing test**

```swift
@MainActor
func test_today_report_view_model_loads_latest_report_summary() throws {
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

    let viewModel = TodayReportViewModel(
        repository: repository,
        composer: DailyReportComposer(randomIndexProvider: { _, _ in 0 })
    )

    viewModel.reload()

    XCTAssertEqual(viewModel.presentation?.title, "平衡人类")
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter TodayReportViewModelTests/test_today_report_view_model_loads_latest_report_summary`
Expected: FAIL because the report feature does not exist.

**Step 3: Write minimal implementation**

```swift
@MainActor
final class TodayReportViewModel: ObservableObject {
    @Published private(set) var presentation: DailyReportPresentation?

    func reload() {
        presentation = try? loadLatestPresentation()
    }
}
```

Wire the view model into `AppDependencies`, embed `TodayReportView` into `MainWindowView`, and simplify the menu bar so the report summary and share actions are visible without scanning a long button list.

**Step 4: Run test to verify it passes**

Run: `swift test --filter TodayReportViewModelTests/test_today_report_view_model_loads_latest_report_summary`
Expected: PASS

**Step 5: Commit**

```bash
git add MoyuCounter/Features/Report/TodayReportView.swift MoyuCounter/Features/Report/TodayReportViewModel.swift MoyuCounter/App/AppDependencies.swift MoyuCounter/Features/MainWindow/MainWindowView.swift MoyuCounter/Features/MenuBar/MenuBarRootView.swift MoyuCounter/Features/MenuBar/MenuBarViewModel.swift MoyuCounter/App/AppStrings.swift MoyuCounterTests/Report/TodayReportViewModelTests.swift MoyuCounterTests/MenuBar/MenuBarViewModelTests.swift
git commit -m "feat: add today report entry points"
```

### Task 6: Extend history for replay and re-share

**Files:**
- Modify: `MoyuCounter/Features/History/HistoryViewModel.swift`
- Modify: `MoyuCounter/Features/History/HistoryView.swift`
- Modify: `MoyuCounter/App/AppDependencies.swift`
- Modify: `MoyuCounter/Core/Poster/PosterExportService.swift`
- Modify: `MoyuCounterTests/History/HistoryViewModelTests.swift`

**Step 1: Write the failing test**

```swift
func test_history_exposes_latest_presentations_for_re_share() throws {
    let repository = try DailyRecordRepository.inMemory()
    try repository.save(
        DailyRecord(
            date: Date(timeIntervalSince1970: 86_400),
            score: 18,
            moyuScore: 82,
            label: DailyScoreLabel.moyuMaster.rawValue,
            activeMinutes: 20,
            trackedMinutes: 480,
            highActivityMinutes: 0,
            lowActivityMinutes: 320,
            longestIdleMinutes: 120
        )
    )

    let viewModel = HistoryViewModel(
        repository: repository,
        composer: DailyReportComposer(randomIndexProvider: { _, _ in 0 })
    )

    viewModel.reload()

    XCTAssertEqual(viewModel.records.first?.presentationTitle, "摸鱼大师")
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter HistoryViewModelTests/test_history_exposes_latest_presentations_for_re_share`
Expected: FAIL because `HistoryViewModel` still exposes raw `DailyRecord` values only.

**Step 3: Write minimal implementation**

```swift
struct HistoryRecordRow: Equatable {
    let date: Date
    let scoreText: String
    let presentationTitle: String
    let verdict: String
}
```

Update `HistoryViewModel` to project stored records into share-ready row data and expose a “copy this day’s report” action via `PosterExportService`.

**Step 4: Run test to verify it passes**

Run: `swift test --filter HistoryViewModelTests/test_history_exposes_latest_presentations_for_re_share`
Expected: PASS

**Step 5: Commit**

```bash
git add MoyuCounter/Features/History/HistoryViewModel.swift MoyuCounter/Features/History/HistoryView.swift MoyuCounter/App/AppDependencies.swift MoyuCounter/Core/Poster/PosterExportService.swift MoyuCounterTests/History/HistoryViewModelTests.swift
git commit -m "feat: allow history re-share of daily reports"
```

