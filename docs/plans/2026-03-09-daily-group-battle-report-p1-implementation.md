# Daily Group Battle Report P1 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add verdict re-roll on today's report and upgrade settlement notifications so they feel like share-first result prompts.

**Architecture:** Keep verdict re-roll local by recomposing the latest stored `DailyRecord` into a new `DailyReportPresentation` without mutating score data. Upgrade notifications inside the existing settlement pipeline by emitting label-aware, share-oriented copy while keeping the notifier abstraction simple and testable.

**Tech Stack:** Swift 6.1, SwiftUI, UserNotifications, XCTest

---

> Current workspace note: this directory does not currently appear to be a Git repository. The commit steps below assume the project will be initialized in Git before execution; otherwise skip the commit step or initialize Git first.

### Task 1: Re-roll verdict copy from today's report card

**Files:**
- Modify: `MoyuCounter/Features/Report/TodayReportViewModel.swift`
- Modify: `MoyuCounter/Features/Report/TodayReportView.swift`
- Modify: `MoyuCounter/Features/MainWindow/MainWindowView.swift`
- Modify: `MoyuCounter/Features/MenuBar/MenuBarRootView.swift`
- Modify: `MoyuCounter/App/AppStrings.swift`
- Modify: `MoyuCounterTests/Report/TodayReportViewModelTests.swift`

**Step 1: Write the failing test**

```swift
@MainActor
func test_refresh_verdict_rebuilds_presentation_without_changing_score_text() throws {
    let repository = try DailyRecordRepository.inMemory()
    try repository.save(
        DailyRecord(
            date: Date(),
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

    var indexes = [0, 1].makeIterator()
    let viewModel = TodayReportViewModel(
        repository: repository,
        composer: DailyReportComposer(randomIndexProvider: { _, _ in indexes.next() ?? 1 })
    )
    let original = try XCTUnwrap(viewModel.presentation)

    viewModel.refreshVerdict()

    XCTAssertNotEqual(viewModel.presentation?.verdict, original.verdict)
    XCTAssertEqual(viewModel.presentation?.laborScoreText, original.laborScoreText)
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter TodayReportViewModelTests/test_refresh_verdict_rebuilds_presentation_without_changing_score_text`
Expected: FAIL because `TodayReportViewModel` has no re-roll API yet.

**Step 3: Write minimal implementation**

```swift
func refreshVerdict() {
    guard let latest = try? repository.fetchLatest() else { return }
    presentation = composer.makePresentation(from: latest)
}
```

Add a `刷新判词` button to `TodayReportView`, wired from both main window and menu bar.

**Step 4: Run test to verify it passes**

Run: `swift test --filter TodayReportViewModelTests/test_refresh_verdict_rebuilds_presentation_without_changing_score_text`
Expected: PASS

**Step 5: Commit**

```bash
git add MoyuCounter/Features/Report/TodayReportViewModel.swift MoyuCounter/Features/Report/TodayReportView.swift MoyuCounter/Features/MainWindow/MainWindowView.swift MoyuCounter/Features/MenuBar/MenuBarRootView.swift MoyuCounter/App/AppStrings.swift MoyuCounterTests/Report/TodayReportViewModelTests.swift
git commit -m "feat: add verdict reroll for today's report"
```

### Task 2: Upgrade daily settlement notifications with result-first copy

**Files:**
- Modify: `MoyuCounter/Core/Settlement/DailySettlementService.swift`
- Modify: `MoyuCounter/Core/Notifications/NotificationService.swift`
- Modify: `MoyuCounter/App/AppStrings.swift`
- Modify: `MoyuCounterTests/Settlement/DailySettlementServiceTests.swift`

**Step 1: Write the failing test**

```swift
func test_settlement_notification_uses_label_and_share_prompt_copy() throws {
    let aggregator = MinuteBucketAggregator()
    aggregator.record(timestamp: Date(timeIntervalSince1970: 0))

    let notifier = CapturingNotifier()
    let service = DailySettlementService(
        aggregator: aggregator,
        windowProvider: StubTrackingWindowProvider(range: 0...0),
        calculator: DailyScoreCalculator(),
        repository: try DailyRecordRepository.inMemory(),
        notifier: notifier
    )

    _ = try service.settle(for: Date(timeIntervalSince1970: 120))

    XCTAssertTrue(notifier.messages[0].title.contains("今日已结算"))
    XCTAssertTrue(notifier.messages[0].subtitle.contains("打开应用"))
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter DailySettlementServiceTests/test_settlement_notification_uses_label_and_share_prompt_copy`
Expected: FAIL because the notification copy still uses the old score-only wording.

**Step 3: Write minimal implementation**

```swift
notifier.postDailyResult(
    title: "今日已结算：\(scoreResult.label.displayTitle)",
    subtitle: "摸鱼分 \(scoreResult.moyuScore) · 打开应用可复制今日战报"
)
```

Add any needed string constants so the copy remains centralized.

**Step 4: Run test to verify it passes**

Run: `swift test --filter DailySettlementServiceTests/test_settlement_notification_uses_label_and_share_prompt_copy`
Expected: PASS

**Step 5: Commit**

```bash
git add MoyuCounter/Core/Settlement/DailySettlementService.swift MoyuCounter/Core/Notifications/NotificationService.swift MoyuCounter/App/AppStrings.swift MoyuCounterTests/Settlement/DailySettlementServiceTests.swift
git commit -m "feat: upgrade settlement notification copy"
```
