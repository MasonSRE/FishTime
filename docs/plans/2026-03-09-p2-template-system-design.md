# P2 模板系统设计稿

## 1. 背景

基于 [PRD：每日群聊战报](/Users/tuboshu/Desktop/ops-2026/APP/摸鱼统计器/docs/prd/2026-03-09-daily-group-battle-report-prd.md)，P0 / P1 已完成，当前进入 P2 的 `多模板系统`。现有实现已经具备：

- 结算后生成稳定的 `DailyRecord`
- 组合今日战报展示模型
- 导出单一海报模板
- 主窗口、菜单栏、历史页完成复制/保存入口

当前缺口不在于“能不能生成战报”，而在于“战报有没有足够强的分享感”。现有 `PosterTemplate` 仅根据称号切换配色，`PosterRenderer` 也还是固定版式，无法支撑更强的社群分享体验。

## 2. 本轮目标

本轮目标限定为：

1. 把当前单一战报卡扩展为 3 套可切换模板
2. 模板切换入口放在今日战报页，并支持实时预览
3. 记住用户上次选择的模板
4. 复制、保存、历史重复制都沿用当前模板

本轮不包含：

- 周报 / 月报
- AI 文案 / AI 海报
- 模板 marketplace 或外部配置系统
- 为历史记录保存“当时使用过的模板”

## 3. 方案对比

### 方案 A：模板枚举 + 渲染策略

- 用枚举表达有限模板集合
- `composer` 负责内容编排，`renderer` 负责按模板绘制
- `SettingsStore` 负责记忆模板选择

优点：

- 与当前项目结构最匹配
- 对日结、存储、历史记录影响最小
- TDD 路径清晰，适合先落地 2 到 3 套模板

缺点：

- 这一轮更适合同一份数据的多种表达，而不是每套模板都拥有完全不同的数据模型

### 方案 B：模板专属展示模型

- 每套模板拥有独立的 section 结构和展示模型

优点：

- 模板表达自由度高

缺点：

- 改动面太大，会连带重构 composer、preview、导出、历史重复制
- 对当前阶段属于超前设计

### 方案 C：配置驱动模板描述符

- 用 descriptor 配置颜色、布局、文案槽位，再由 renderer 解释执行

优点：

- 后续继续扩模板速度快

缺点：

- 当前模板数量很少，配置层会先带来额外复杂度
- AppKit 手写绘制坐标下，descriptor 不一定比直接渲染分支更省事

### 结论

选用 `方案 A：模板枚举 + 渲染策略`。先建立稳定模板骨架，再视 P2 后续需求决定是否继续向更抽象的模板系统演进。

## 4. 设计决策

### 4.1 数据与状态

- 不修改 `DailyRecord`
- 新增 `ReportTemplateStyle` 枚举，首轮包含 3 个模板：
  - `standard`
  - `certificate`
  - `deskLog`
- `SettingsStore` 新增 `selectedReportTemplate`
- `DailyReportPresentation` 增加 `templateStyle`
- `DailyReportComposer.makePresentation(from:templateStyle:)` 接收模板参数，用于微调标题、统计项顺序、分享文案首行

边界：

- 模板切换不写入数据库
- 历史记录不保存“当年使用模板”，旧记录永远按“当前全局模板”重新生成

### 4.2 界面与交互

- `TodayReportView` 升级为三段结构：
  - 模板切换条
  - 当前模板预览区
  - 分享动作区
- 用户点击模板后立即切换预览，并同步写入 `SettingsStore`
- `刷新判词` 只刷新文案，不改变模板与分数
- `复制今日战报`、`保存战报图片` 使用当前模板
- 菜单栏紧凑视图不提供模板切换，只复用当前全局模板

### 4.3 渲染与导出

- `PosterRenderer` 按 `templateStyle` 分发到不同私有渲染函数
- 首轮模板定位：
  - `standard`：延续现有结果卡风格，平滑升级
  - `certificate`：更强调纪念感、称号与日期
  - `deskLog`：更强调统计项与群聊吐槽感
- `PosterExportService` 统一使用当前模板生成 PNG 与 shareText
- `HistoryViewModel.copyReport(for:)` 走同一导出链路，确保旧记录重复制行为一致

### 4.4 测试范围

新增或更新测试覆盖：

- `SettingsStoreTests`
  - 默认模板
  - 模板持久化
- `DailyReportComposerTests`
  - 同一条记录在不同模板下的共同字段保持稳定
  - 模板相关字段存在差异
- `TodayReportViewModelTests`
  - 启动时读取已保存模板
  - 切换模板后更新 presentation 并回写设置
  - 刷新判词不重置模板
- `PosterRendererTests`
  - 三种模板都能成功生成 PNG
- `HistoryViewModelTests`
  - 历史重复制沿用当前全局模板
- `PosterExportServiceTests`
  - 复制 / 保存使用当前模板生成 payload

## 5. 影响范围

预计修改路径：

- `MoyuCounter/Core/Poster/*`
- `MoyuCounter/Core/Sharing/*`
- `MoyuCounter/Core/Settings/SettingsStore.swift`
- `MoyuCounter/Features/Report/*`
- `MoyuCounter/Features/History/HistoryViewModel.swift`
- `MoyuCounter/Features/MenuBar/MenuBarViewModel.swift`
- `MoyuCounter/App/AppDependencies.swift`
- 对应 XCTest 文件

## 6. 风险与约束

### 风险 1：渲染层分支膨胀

控制方式：

- 保持模板数固定为 3
- 共用文字绘制和色板辅助函数
- 不在本轮引入配置驱动 descriptor

### 风险 2：预览与导出不一致

控制方式：

- 预览和导出统一使用 `DailyReportPresentation.templateStyle`
- 所有分享入口都从同一模板状态读取

### 风险 3：模板切换影响现有分享链路

控制方式：

- 先补测试，再改导出与 view model
- 保持 `DailyRecord` 与分数计算完全不动

## 7. 验收标准

满足以下条件即视为本轮完成：

1. 今日战报页可切换 3 套模板，并实时预览
2. 关闭重开应用后，仍恢复上次模板选择
3. 复制与保存得到的海报与当前预览模板一致
4. 历史页“复制这天战报”沿用当前全局模板
5. `swift test` 全量通过
