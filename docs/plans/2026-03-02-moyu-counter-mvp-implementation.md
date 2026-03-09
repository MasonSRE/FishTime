# Moyu Counter MVP Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a native macOS menu bar app that tracks input activity, computes daily score, and generates humorous poster locally.

**Architecture:** Use a modular SwiftUI app with a MenuBar entry point, a local event-count collector, a rule-based scoring service, and a local poster renderer. Keep all data in local SQLite and expose a minimal settings + history UX for a stable MVP loop.

**Tech Stack:** Swift 5.10+, SwiftUI, AppKit/Quartz event APIs, SQLite, UserNotifications, XCTest

---

### Task 1: Project Skeleton and Menu Bar Entry

**Files:**
- Create: `MoyuCounter/MoyuCounterApp.swift`
- Create: `MoyuCounter/Features/MenuBar/MenuBarRootView.swift`
- Create: `MoyuCounter/Features/MenuBar/MenuBarViewModel.swift`
- Create: `MoyuCounter/Resources/Assets.xcassets` (icon placeholders)
- Test: `MoyuCounterTests/MenuBar/MenuBarViewModelTests.swift`

**Step 1: Write the failing test**

```swift
func test_menu_bar_initial_state_is_idle() {
    let vm = MenuBarViewModel()
    XCTAssertEqual(vm.statusText, "Not Started")
}
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme MoyuCounter -destination 'platform=macOS' -only-testing:MoyuCounterTests/MenuBarViewModelTests/test_menu_bar_initial_state_is_idle`
Expected: FAIL due to missing `MenuBarViewModel`.

**Step 3: Write minimal implementation**

```swift
final class MenuBarViewModel: ObservableObject {
    @Published var statusText: String = "Not Started"
}
```

**Step 4: Run test to verify it passes**

Run: same `xcodebuild` command
Expected: PASS.

**Step 5: Commit**

```bash
git add MoyuCounter/MoyuCounterApp.swift MoyuCounter/Features/MenuBar/MenuBarRootView.swift MoyuCounter/Features/MenuBar/MenuBarViewModel.swift MoyuCounterTests/MenuBar/MenuBarViewModelTests.swift
git commit -m "feat: add menu bar app skeleton and initial state"
```

### Task 2: Preferences and Work Schedule Settings

**Files:**
- Create: `MoyuCounter/Features/Settings/SettingsView.swift`
- Create: `MoyuCounter/Core/Settings/SettingsStore.swift`
- Create: `MoyuCounter/Core/Settings/TrackingScope.swift`
- Test: `MoyuCounterTests/Settings/SettingsStoreTests.swift`

**Step 1: Write the failing test**

```swift
func test_default_scope_is_work_hours_only() {
    let store = SettingsStore(userDefaults: .standard)
    XCTAssertEqual(store.scope, .workHoursOnly)
}
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme MoyuCounter -destination 'platform=macOS' -only-testing:MoyuCounterTests/SettingsStoreTests/test_default_scope_is_work_hours_only`
Expected: FAIL because `SettingsStore` does not exist.

**Step 3: Write minimal implementation**

```swift
enum TrackingScope: String { case workHoursOnly, wholeDay }
```

```swift
final class SettingsStore {
    var scope: TrackingScope = .workHoursOnly
}
```

**Step 4: Run test to verify it passes**

Run: same `xcodebuild` command
Expected: PASS.

**Step 5: Commit**

```bash
git add MoyuCounter/Features/Settings/SettingsView.swift MoyuCounter/Core/Settings/SettingsStore.swift MoyuCounter/Core/Settings/TrackingScope.swift MoyuCounterTests/Settings/SettingsStoreTests.swift
git commit -m "feat: add settings store with tracking scope and schedule config"
```

### Task 3: Activity Collector with Minute Aggregation

**Files:**
- Create: `MoyuCounter/Core/ActivityCollector/ActivityEvent.swift`
- Create: `MoyuCounter/Core/ActivityCollector/ActivityCollector.swift`
- Create: `MoyuCounter/Core/ActivityCollector/MinuteBucketAggregator.swift`
- Test: `MoyuCounterTests/ActivityCollector/MinuteBucketAggregatorTests.swift`

**Step 1: Write the failing test**

```swift
func test_aggregator_counts_events_per_minute() {
    let agg = MinuteBucketAggregator()
    agg.record(timestamp: Date(timeIntervalSince1970: 60))
    agg.record(timestamp: Date(timeIntervalSince1970: 61))
    XCTAssertEqual(agg.count(forEpochMinute: 1), 2)
}
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme MoyuCounter -destination 'platform=macOS' -only-testing:MoyuCounterTests/MinuteBucketAggregatorTests/test_aggregator_counts_events_per_minute`
Expected: FAIL because aggregator implementation is missing.

**Step 3: Write minimal implementation**

```swift
final class MinuteBucketAggregator {
    private var buckets: [Int: Int] = [:]
    func record(timestamp: Date) { buckets[Int(timestamp.timeIntervalSince1970) / 60, default: 0] += 1 }
    func count(forEpochMinute minute: Int) -> Int { buckets[minute] ?? 0 }
}
```

**Step 4: Run test to verify it passes**

Run: same `xcodebuild` command
Expected: PASS.

**Step 5: Commit**

```bash
git add MoyuCounter/Core/ActivityCollector/ActivityEvent.swift MoyuCounter/Core/ActivityCollector/ActivityCollector.swift MoyuCounter/Core/ActivityCollector/MinuteBucketAggregator.swift MoyuCounterTests/ActivityCollector/MinuteBucketAggregatorTests.swift
git commit -m "feat: add input activity collection and minute bucket aggregation"
```

### Task 4: Daily Scoring Engine (Rule-Based)

**Files:**
- Create: `MoyuCounter/Core/Scoring/ScoringThresholds.swift`
- Create: `MoyuCounter/Core/Scoring/DailyScoreCalculator.swift`
- Create: `MoyuCounter/Core/Scoring/DailyScoreResult.swift`
- Test: `MoyuCounterTests/Scoring/DailyScoreCalculatorTests.swift`

**Step 1: Write the failing test**

```swift
func test_high_activity_day_is_classified_as_top_niuma() {
    let calculator = DailyScoreCalculator()
    let result = calculator.calculate(from: [.init(epm: 20, minutes: 480)])
    XCTAssertGreaterThanOrEqual(result.laborScore, 75)
    XCTAssertEqual(result.label, .topNiuMa)
}
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme MoyuCounter -destination 'platform=macOS' -only-testing:MoyuCounterTests/DailyScoreCalculatorTests/test_high_activity_day_is_classified_as_top_niuma`
Expected: FAIL because `DailyScoreCalculator` is missing.

**Step 3: Write minimal implementation**

```swift
func laborScore(highRatio: Double, lowRatio: Double, idleRatio: Double) -> Int {
    let raw = 100.0 * (0.55 * highRatio + 0.25 * (1 - lowRatio) + 0.20 * (1 - idleRatio))
    return max(0, min(100, Int(raw.rounded())))
}
```

**Step 4: Run test to verify it passes**

Run: same `xcodebuild` command
Expected: PASS.

**Step 5: Commit**

```bash
git add MoyuCounter/Core/Scoring/ScoringThresholds.swift MoyuCounter/Core/Scoring/DailyScoreCalculator.swift MoyuCounter/Core/Scoring/DailyScoreResult.swift MoyuCounterTests/Scoring/DailyScoreCalculatorTests.swift
git commit -m "feat: implement v1 daily scoring engine and labels"
```

### Task 5: Local Storage for Daily Records

**Files:**
- Create: `MoyuCounter/Core/Storage/Database.swift`
- Create: `MoyuCounter/Core/Storage/DailyRecordRepository.swift`
- Create: `MoyuCounter/Core/Storage/DailyRecord.swift`
- Test: `MoyuCounterTests/Storage/DailyRecordRepositoryTests.swift`

**Step 1: Write the failing test**

```swift
func test_save_and_fetch_latest_daily_record() throws {
    let repo = try DailyRecordRepository.inMemory()
    try repo.save(.sample(score: 66))
    let latest = try repo.fetchLatest()
    XCTAssertEqual(latest?.score, 66)
}
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme MoyuCounter -destination 'platform=macOS' -only-testing:MoyuCounterTests/DailyRecordRepositoryTests/test_save_and_fetch_latest_daily_record`
Expected: FAIL due to missing repository.

**Step 3: Write minimal implementation**

```swift
struct DailyRecord { let date: Date; let score: Int; let label: String }
```

```swift
final class DailyRecordRepository {
    func save(_ record: DailyRecord) throws {}
    func fetchLatest() throws -> DailyRecord? { nil }
}
```

**Step 4: Run test to verify it passes**

Run: same `xcodebuild` command
Expected: PASS after implementing real save/fetch logic.

**Step 5: Commit**

```bash
git add MoyuCounter/Core/Storage/Database.swift MoyuCounter/Core/Storage/DailyRecordRepository.swift MoyuCounter/Core/Storage/DailyRecord.swift MoyuCounterTests/Storage/DailyRecordRepositoryTests.swift
git commit -m "feat: add local daily record persistence"
```

### Task 6: Poster Generation from Local Templates

**Files:**
- Create: `MoyuCounter/Core/Poster/PosterTemplate.swift`
- Create: `MoyuCounter/Core/Poster/PosterRenderer.swift`
- Create: `MoyuCounter/Resources/Posters/` (template assets)
- Test: `MoyuCounterTests/Poster/PosterRendererTests.swift`

**Step 1: Write the failing test**

```swift
func test_renderer_returns_image_data_for_valid_result() throws {
    let renderer = PosterRenderer()
    let data = try renderer.render(result: .sampleMoyuMaster)
    XCTAssertFalse(data.isEmpty)
}
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme MoyuCounter -destination 'platform=macOS' -only-testing:MoyuCounterTests/PosterRendererTests/test_renderer_returns_image_data_for_valid_result`
Expected: FAIL because renderer is missing.

**Step 3: Write minimal implementation**

```swift
final class PosterRenderer {
    func render(result: DailyScoreResult) throws -> Data { Data([0x89, 0x50, 0x4E, 0x47]) }
}
```

**Step 4: Run test to verify it passes**

Run: same `xcodebuild` command
Expected: PASS with real PNG output.

**Step 5: Commit**

```bash
git add MoyuCounter/Core/Poster/PosterTemplate.swift MoyuCounter/Core/Poster/PosterRenderer.swift MoyuCounter/Resources/Posters MoyuCounterTests/Poster/PosterRendererTests.swift
git commit -m "feat: add template-based humorous poster generation"
```

### Task 7: Day-End Settlement and Notification

**Files:**
- Create: `MoyuCounter/Core/Scheduler/DayEndScheduler.swift`
- Create: `MoyuCounter/Core/Notifications/NotificationService.swift`
- Modify: `MoyuCounter/Features/MenuBar/MenuBarViewModel.swift`
- Test: `MoyuCounterTests/Scheduler/DayEndSchedulerTests.swift`

**Step 1: Write the failing test**

```swift
func test_scheduler_triggers_settlement_once_per_day() {
    let scheduler = DayEndScheduler(clock: .fixed("2026-03-02T23:59:00Z"))
    XCTAssertTrue(scheduler.shouldRunSettlement())
}
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme MoyuCounter -destination 'platform=macOS' -only-testing:MoyuCounterTests/DayEndSchedulerTests/test_scheduler_triggers_settlement_once_per_day`
Expected: FAIL because scheduler logic is missing.

**Step 3: Write minimal implementation**

```swift
final class DayEndScheduler {
    func shouldRunSettlement() -> Bool { false }
}
```

**Step 4: Run test to verify it passes**

Run: same `xcodebuild` command
Expected: PASS with once-per-day trigger logic.

**Step 5: Commit**

```bash
git add MoyuCounter/Core/Scheduler/DayEndScheduler.swift MoyuCounter/Core/Notifications/NotificationService.swift MoyuCounter/Features/MenuBar/MenuBarViewModel.swift MoyuCounterTests/Scheduler/DayEndSchedulerTests.swift
git commit -m "feat: add day-end settlement trigger and local notifications"
```

### Task 8: History View and Data Reset

**Files:**
- Create: `MoyuCounter/Features/History/HistoryView.swift`
- Create: `MoyuCounter/Features/History/HistoryViewModel.swift`
- Modify: `MoyuCounter/Features/Settings/SettingsView.swift`
- Test: `MoyuCounterTests/History/HistoryViewModelTests.swift`

**Step 1: Write the failing test**

```swift
func test_history_returns_max_30_days() {
    let vm = HistoryViewModel(repository: .mockWith40Records)
    XCTAssertEqual(vm.records.count, 30)
}
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme MoyuCounter -destination 'platform=macOS' -only-testing:MoyuCounterTests/HistoryViewModelTests/test_history_returns_max_30_days`
Expected: FAIL because history view model is missing.

**Step 3: Write minimal implementation**

```swift
final class HistoryViewModel: ObservableObject {
    @Published private(set) var records: [DailyRecord] = []
}
```

**Step 4: Run test to verify it passes**

Run: same `xcodebuild` command
Expected: PASS with capped list logic and reset support.

**Step 5: Commit**

```bash
git add MoyuCounter/Features/History/HistoryView.swift MoyuCounter/Features/History/HistoryViewModel.swift MoyuCounter/Features/Settings/SettingsView.swift MoyuCounterTests/History/HistoryViewModelTests.swift
git commit -m "feat: add 30-day history view and data reset flow"
```

### Task 9: MVP Verification and Release Checklist

**Files:**
- Create: `docs/release/moyu-counter-mvp-checklist.md`
- Modify: `README.md`

**Step 1: Write verification checklist**

```markdown
- [ ] First-run permission flow works
- [ ] Scope toggle switches calculation window
- [ ] Day-end score generated offline
- [ ] Poster save/copy works
- [ ] Reset deletes local records
```

**Step 2: Run full tests**

Run: `xcodebuild test -scheme MoyuCounter -destination 'platform=macOS'`
Expected: PASS all tests.

**Step 3: Run static checks**

Run: `xcodebuild -scheme MoyuCounter -destination 'platform=macOS' build`
Expected: BUILD SUCCEEDED.

**Step 4: Update docs**

```markdown
Add setup, permissions, and privacy behavior to README.
```

**Step 5: Commit**

```bash
git add docs/release/moyu-counter-mvp-checklist.md README.md
git commit -m "docs: add mvp verification checklist and usage notes"
```
