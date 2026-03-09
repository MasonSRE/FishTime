# 摸鱼统计器 App 形态升级与全量汉化 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 将应用升级为“Dock 图标 + 主窗口 + 菜单栏”双入口形态，并完成面向用户界面的全量中文化与鱼主题 App 图标接入。

**Architecture:** 继续复用现有 `AppDependencies` 与各 Feature ViewModel，新增主窗口场景并保持菜单栏入口。文案通过集中常量层管理，统一替换 UI、状态反馈、通知和海报文本。打包链路通过 `.icns` 资源与 `Info.plist` 字段完成 App 图标声明。

**Tech Stack:** SwiftUI, AppKit, Swift Package Manager, XCTest, Bash (macOS packaging scripts)

---

### Task 1: 建立统一中文文案层并替换 UI 可见文案

**Files:**
- Create: `MoyuCounter/App/AppStrings.swift`
- Modify: `MoyuCounter/Features/MenuBar/MenuBarRootView.swift`
- Modify: `MoyuCounter/Features/Permissions/PermissionOnboardingView.swift`
- Modify: `MoyuCounter/Features/Settings/SettingsView.swift`
- Modify: `MoyuCounter/Features/History/HistoryView.swift`
- Modify: `MoyuCounter/MoyuCounterApp.swift`

**Step 1: Write the failing test**

```swift
func test_initial_message_reflects_denied_status() {
    let permissionManager = StubPermissionManager(status: .denied, requestResult: false)
    let viewModel = PermissionOnboardingViewModel(permissionManager: permissionManager)

    XCTAssertEqual(viewModel.message, "权限被拒绝，请在系统设置中开启辅助功能权限。")
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter PermissionOnboardingViewModelTests/test_initial_message_reflects_denied_status`
Expected: FAIL with old English message mismatch.

**Step 3: Write minimal implementation**

```swift
enum AppStrings {
    enum Permission {
        static let denied = "权限被拒绝，请在系统设置中开启辅助功能权限。"
    }
}
```

```swift
// Replace PermissionOnboardingViewModel / Views literal strings
message = AppStrings.Permission.denied
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter PermissionOnboardingViewModelTests/test_initial_message_reflects_denied_status`
Expected: PASS.

**Step 5: Commit**

```bash
git add MoyuCounter/App/AppStrings.swift \
  MoyuCounter/Features/MenuBar/MenuBarRootView.swift \
  MoyuCounter/Features/Permissions/PermissionOnboardingView.swift \
  MoyuCounter/Features/Settings/SettingsView.swift \
  MoyuCounter/Features/History/HistoryView.swift \
  MoyuCounter/MoyuCounterApp.swift \
  MoyuCounterTests/Permissions/PermissionOnboardingViewModelTests.swift
git commit -m "feat: add centralized Chinese UI strings and localize feature views"
```

### Task 2: 汉化状态反馈、评分文案、通知与海报文本

**Files:**
- Modify: `MoyuCounter/Features/MenuBar/MenuBarViewModel.swift`
- Modify: `MoyuCounter/Features/Permissions/PermissionOnboardingViewModel.swift`
- Modify: `MoyuCounter/Core/Scoring/DailyScoreCalculator.swift`
- Modify: `MoyuCounter/Core/Scoring/DailyScoreResult.swift`
- Modify: `MoyuCounter/Core/Settlement/DailySettlementService.swift`
- Modify: `MoyuCounter/Core/Poster/PosterTemplate.swift`
- Modify: `MoyuCounter/Core/Poster/PosterRenderer.swift`
- Modify: `MoyuCounterTests/MenuBar/MenuBarViewModelTests.swift`
- Modify: `MoyuCounterTests/Permissions/PermissionOnboardingViewModelTests.swift`
- Modify: `MoyuCounterTests/Scoring/DailyScoreCalculatorTests.swift`

**Step 1: Write the failing test**

```swift
func test_check_for_settlement_updates_status_when_scheduler_triggers() {
    // ...
    vm.checkForSettlement()
    XCTAssertEqual(vm.statusText, "已结算：88")
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter MenuBarViewModelTests/test_check_for_settlement_updates_status_when_scheduler_triggers`
Expected: FAIL with old English status text.

**Step 3: Write minimal implementation**

```swift
statusText = "已结算：\(record.score)"
```

```swift
notifier.postDailyResult(
    title: "今日得分：\(scoreResult.laborScore)",
    subtitle: scoreResult.oneLiner
)
```

```swift
return "键盘冒火星，鼠标擦出电。"
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter MenuBarViewModelTests/test_check_for_settlement_updates_status_when_scheduler_triggers`
Expected: PASS.

**Step 5: Commit**

```bash
git add MoyuCounter/Features/MenuBar/MenuBarViewModel.swift \
  MoyuCounter/Features/Permissions/PermissionOnboardingViewModel.swift \
  MoyuCounter/Core/Scoring/DailyScoreCalculator.swift \
  MoyuCounter/Core/Scoring/DailyScoreResult.swift \
  MoyuCounter/Core/Settlement/DailySettlementService.swift \
  MoyuCounter/Core/Poster/PosterTemplate.swift \
  MoyuCounter/Core/Poster/PosterRenderer.swift \
  MoyuCounterTests/MenuBar/MenuBarViewModelTests.swift \
  MoyuCounterTests/Permissions/PermissionOnboardingViewModelTests.swift \
  MoyuCounterTests/Scoring/DailyScoreCalculatorTests.swift
git commit -m "feat: localize runtime status, scoring copy, notifications and poster text"
```

### Task 3: 增加主窗口入口并保留菜单栏快捷入口

**Files:**
- Create: `MoyuCounter/Features/MainWindow/MainWindowView.swift`
- Modify: `MoyuCounter/MoyuCounterApp.swift`

**Step 1: Write the failing test**

```swift
func test_menu_bar_initial_state_is_idle() {
    let vm = MenuBarViewModel(/* stubs */)
    XCTAssertEqual(vm.statusText, "未开始")
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter MenuBarViewModelTests/test_menu_bar_initial_state_is_idle`
Expected: FAIL if status default is still old value.

**Step 3: Write minimal implementation**

```swift
Window("摸鱼统计器", id: "main-window") {
    MainWindowView(
        menuBarViewModel: dependencies.menuBarViewModel,
        permissionViewModel: dependencies.permissionViewModel,
        openHistory: { /* open history window */ },
        openSettings: { /* show settings */ }
    )
}
```

```swift
MenuBarExtra("摸鱼统计器", systemImage: "fish") { ... }
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter MenuBarViewModelTests/test_menu_bar_initial_state_is_idle`
Expected: PASS.

**Step 5: Commit**

```bash
git add MoyuCounter/Features/MainWindow/MainWindowView.swift \
  MoyuCounter/MoyuCounterApp.swift \
  MoyuCounterTests/MenuBar/MenuBarViewModelTests.swift
git commit -m "feat: add main app window while keeping menu bar quick actions"
```

### Task 4: 接入鱼主题 App 图标到打包产物

**Files:**
- Create: `MoyuCounter/Resources/AppIcon.icns`
- Create: `scripts/generate_app_icon.sh` (可重复生成占位鱼图标)
- Modify: `scripts/package_macos_app.sh`

**Step 1: Write the failing verification**

```bash
./scripts/package_macos_app.sh
plutil -extract CFBundleIconFile raw dist/MoyuCounter.app/Contents/Info.plist
```

Expected: currently missing `CFBundleIconFile` or icon file not present.

**Step 2: Run verification to confirm failure**

Run: `./scripts/package_macos_app.sh && test -f dist/MoyuCounter.app/Contents/Resources/AppIcon.icns`
Expected: FAIL before script/resource update.

**Step 3: Write minimal implementation**

```bash
cp "$ROOT_DIR/MoyuCounter/Resources/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"
```

```xml
<key>CFBundleIconFile</key>
<string>AppIcon</string>
```

**Step 4: Run verification to verify it passes**

Run:
- `./scripts/package_macos_app.sh`
- `test -f dist/MoyuCounter.app/Contents/Resources/AppIcon.icns`
- `plutil -extract CFBundleIconFile raw dist/MoyuCounter.app/Contents/Info.plist`

Expected: pass and output `AppIcon`.

**Step 5: Commit**

```bash
git add MoyuCounter/Resources/AppIcon.icns scripts/generate_app_icon.sh scripts/package_macos_app.sh
git commit -m "feat: add fish app icon and wire it into macOS packaging"
```

### Task 5: 全量回归验证与文档更新

**Files:**
- Modify: `README.md`
- Modify: `docs/release/xcode-distribution.md` (if icon packaging notes changed)

**Step 1: Write the failing verification checklist**

```text
1) 所有核心测试通过
2) 打包后应用含主窗口、菜单栏入口、鱼图标
3) UI 不再出现关键英文按钮/状态
```

**Step 2: Run verification to find failures**

Run:
- `swift test`
- `./scripts/package_macos_app.sh`
- `rg '\"[^\"]*[A-Za-z][^\"]*\"' MoyuCounter/Features MoyuCounter/MoyuCounterApp.swift`

Expected: before最终修正可能仍有英文残留。

**Step 3: Write minimal implementation**

```markdown
## 运行形态
- 应用默认以主窗口启动，并提供菜单栏快捷入口。
## 图标
- 默认使用鱼主题 `AppIcon.icns`。
```

**Step 4: Run verification to verify it passes**

Run:
- `swift test`
- `./scripts/package_macos_app.sh`
- manual open `dist/MoyuCounter.app` to verify Dock icon + window + Chinese copy

Expected: all checks pass.

**Step 5: Commit**

```bash
git add README.md docs/release/xcode-distribution.md
git commit -m "docs: update app mode and icon packaging guidance"
```
