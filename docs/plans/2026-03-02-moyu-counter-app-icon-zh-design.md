# 摸鱼统计器 App 形态升级与全量汉化设计

## 1. 目标与范围

- 将产品从“仅菜单栏工具”升级为“标准 macOS 应用”（Dock 图标 + 主窗口），同时保留菜单栏快捷入口。
- 补齐应用图标接入链路，产物 `.app` 在 Finder / Dock / 应用切换器展示鱼主题图标。
- 对面向用户的可见文案进行全量汉化：按钮、选项、状态提示、窗口标题、权限引导、通知、海报文本。

非目标：
- 本次不引入完整多语言体系（`Localizable.strings`），先以中文为默认语言。
- 不改动统计、结算、存储算法本身，只改产品入口形态和文案层。

## 2. 现状分析

- 当前入口是 `MenuBarExtra`，`MoyuCounter/MoyuCounterApp.swift` 未提供主窗口入口，产品体验偏“纯菜单栏工具”。
- 打包脚本 `scripts/package_macos_app.sh` 的 `Info.plist` 尚未声明图标字段，且未复制 `.icns` 到资源目录。
- 文案分散在多个 View / ViewModel / Core 文件中，存在大量英文硬编码，修改成本与漏改风险较高。

## 3. 方案对比与结论

### 方案 A（推荐，已确认）

- 双入口：主窗口 + 菜单栏并存。
- 优点：既有“标准应用”感，也保留菜单栏快速操作；对现有结构改动适中。
- 缺点：需要保证两处入口共享同一状态源，避免状态不一致。

### 方案 B

- 仅主窗口，移除菜单栏。
- 优点：信息架构单一。
- 缺点：损失菜单栏便捷性，不符合当前产品习惯。

### 方案 C

- 保持纯菜单栏，仅做图标与中文化。
- 优点：开发成本最低。
- 缺点：无法满足“不是单纯顶边框工具”的核心诉求。

结论：采用方案 A。

## 4. 设计细节

### 4.1 应用入口与信息架构

- 新增主窗口（默认窗口）作为应用主入口，窗口标题使用中文“摸鱼统计器”。
- 保留 `MenuBarExtra` 作为快捷控制面板（开始/停止、海报、历史、设置）。
- 两个入口共享同一套依赖和状态对象（`AppDependencies`），避免 duplicated state。

### 4.2 图标接入设计

- 新增鱼主题 App 图标资源：`MoyuCounter/Resources/AppIcon.icns`。
- 打包脚本在构建 `.app` 时复制图标到 `Contents/Resources/AppIcon.icns`。
- `Info.plist` 增加：
  - `CFBundleIconFile = AppIcon`
- 通过打包后的 `dist/MoyuCounter.app` 实测图标展示。

### 4.3 全量汉化策略

- 新建集中式文案文件（如 `MoyuCounter/App/AppStrings.swift`），统一管理中文文案常量。
- 修改以下层级的可见文案：
  - 菜单栏视图：状态、今日事件、所有操作按钮。
  - 权限引导：提示语、授权按钮。
  - 设置页：跟踪范围、时间步进器、重置按钮。
  - 历史页：窗口标题及列表相关文本。
  - ViewModel 状态反馈：跟踪中、已停止、结算成功/失败、海报操作结果。
  - 通知文案、海报模板标题与海报分数描述文案。
- 文案风格：简洁、产品化、口语化，避免直译腔。

## 5. 影响面

- UI 层：`MoyuCounterApp.swift`、`Features/*View.swift`
- 业务反馈层：`MenuBarViewModel.swift`、`PermissionOnboardingViewModel.swift`
- 内容输出层：`Core/Settlement/*`、`Core/Poster/*`、`Core/Scoring/*`
- 打包链路：`scripts/package_macos_app.sh`
- 测试：相关断言需更新为中文预期

## 6. 风险与规避

- 风险 1：双入口状态不一致  
  规避：统一 `AppDependencies` 单例化注入同一 ViewModel。
- 风险 2：英文遗漏造成中英混杂  
  规避：用 `rg` 检索英文 UI 关键字符串进行清单式回归。
- 风险 3：图标不生效  
  规避：校验 `.app` 资源目录、`Info.plist` 字段、重新打包后测试。
- 风险 4：测试断言失效  
  规避：同步更新测试文案断言并执行 `swift test`。

## 7. 验收标准

1. 启动后以标准 App 形态可见（Dock 图标 + 主窗口），并保留菜单栏入口。
2. 打包产物展示鱼主题图标（Finder / Dock / 切换器）。
3. 面向用户可见文案均为中文，不出现关键路径英文。
4. `swift test` 全量通过，打包脚本可正常生成可运行 `.app`。
