# P2 周报 / 月报设计稿

## 1. 背景

基于 [PRD：每日群聊战报](/Users/tuboshu/Desktop/ops-2026/APP/摸鱼统计器/.worktrees/p2-weekly-monthly/docs/prd/2026-03-09-daily-group-battle-report-prd.md)，当前项目状态为：

- `P0 / P1` 已完成
- `P2-模板系统` 已完成
- 当前继续进入 `P2-周报 / 月报`

现有实现已经具备：

1. 每日结算会稳定生成 `DailyRecord`
2. 日战报的展示模型、渲染、复制和保存链路已完成
3. 主窗口今日战报页、菜单栏、历史页都已接入导出能力
4. 模板切换与模板持久化已经完成

当前缺口不在于“能不能生成一张图”，而在于“有没有更适合收藏、回看和周期复盘的纪念海报”。P2 的周报 / 月报要在不引入联网、不重做存储模型的前提下，把现有日记录聚合成更有纪念感的周期结果。

## 2. 本轮目标

本轮目标限定为：

1. 基于已有 `DailyRecord` 离线生成 `周报 / 月报纪念海报`
2. 支持 `自然周 / 自然月` 两种统计周期
3. 支持查看 `当前进行中周期` 与 `上一完整周期`
4. 先建立共享的周期生成与导出链路
5. 在 `今日战报页` 和 `历史页` 都接入周期纪念卡入口

本轮不包含：

1. 趋势图、长表格、逐日明细报表
2. 为数据库新增周报 / 月报快照表
3. 自定义日期范围选择器
4. AI 文案或联网排行榜
5. 记录“某张周期海报当时使用过的快照状态”

## 3. 已确认的产品边界

本轮需求已确认如下：

1. 入口方向：`共享生成链路 + 今日页和历史页都接 UI`
2. 内容结构：优先 `纪念海报型`
3. 周期定义：`周报用自然周，月报用自然月`
4. 范围选择：`进行中 + 已结束周期都支持`
5. 默认展示：支持当前进行中周期，并明确标注 `截至今日`

## 4. 方案对比

### 方案 A：独立的周期战报链路

- 为周报 / 月报单独建立聚合、展示模型和渲染器
- 与现有日战报并行存在，只共享导出服务和底层存储

优点：

1. 不污染现有 `DailyReportPresentation` 语义
2. 更适合“纪念海报型”输出
3. 后续扩展收藏感增强时边界清晰

缺点：

1. 会增加一套周期链路代码

### 方案 B：强行复用日战报模型

- 把周报 / 月报也塞进 `DailyReportPresentation` 与现有 `PosterRenderer`

优点：

1. 表面改动少

缺点：

1. 语义会变得混乱
2. 后续 UI、导出、测试会持续膨胀
3. 不适合继续做周期纪念能力

### 方案 C：日结时预生成周期快照

- 在保存每日记录时额外生成周报 / 月报快照并入库

优点：

1. 读取速度快
2. 历史结果稳定

缺点：

1. 当前周期是持续变化的，快照维护复杂
2. 对当前阶段属于过度设计

### 结论

选用 `方案 A：独立的周期战报链路`。现有 `DailyRecord` 已足够支撑离线聚合，不需要新增存储表或重构日战报模型。P2 第一版应先把周期能力做成独立骨架，再视后续收藏感增强需求决定是否做更多抽象。

## 5. 设计决策

### 5.1 系统形状

- 不修改 `DailyRecord`
- 新增周期域模型：
  - `PeriodReportKind`：`.weekly` / `.monthly`
  - `PeriodReportScope`：`.current` / `.previousCompleted`
- `DailyRecordRepository` 新增按时间范围读取记录的能力
- 新增独立链路：
  - `PeriodReportAggregator`
  - `PeriodReportComposer`
  - `PeriodReportPresentation`
  - `PeriodPosterRenderer`
- 导出层继续收口到 `PosterExportService`，为周期海报新增独立复制 / 保存入口

边界：

1. 日结流程保持不变
2. 周报 / 月报完全运行时聚合，不写数据库快照
3. 日战报与周期战报各自维护自己的展示模型

### 5.2 展示内容

第一版按“纪念海报型”收敛，单张周报 / 月报固定包含以下 5 层：

1. `纪念标题`
   - 周报：`本周摸鱼纪念卡`
   - 月报：`本月摸鱼纪念卡`
   - 已结束周期可显示明确周期名，如 `2026年3月月报`
   - 当前进行中周期追加 `截至今日`

2. `周期结论`
   - 基于周期平均劳动分给出一句主结论
   - 不直接复用某一天称号
   - 建议三档：
     - 高分：`工位高燃期`
     - 中间：`人类平衡态`
     - 低分：`稳定潜航期`

3. `核心指标`
   - 固定为 4 项：
     - `记录天数`
     - `平均劳动分`
     - `总活跃分钟`
     - `最长沉寂分钟`

4. `本期亮点`
   - 固定给 2 条：
     - `最拼一天`
     - `最会摸一天`

5. `周期脚注`
   - 展示真实覆盖范围
   - 当前进行中周期补 `截至 <日期>`
   - 保留产品名

### 5.3 聚合规则

周期计算规则如下：

1. `weekly.current`
   - 取当前自然周内，从周一开始到今天的所有记录

2. `weekly.previousCompleted`
   - 取上一个完整自然周，从周一到周日

3. `monthly.current`
   - 取当前自然月内，从月初到今天的所有记录

4. `monthly.previousCompleted`
   - 取上一个完整自然月

通用规则：

1. 周期内只要有 1 条记录就允许生成海报
2. 周期内没有记录则展示空状态，不强行补零海报
3. `平均劳动分` 使用周期内记录的算术平均值
4. `总活跃分钟` 为周期内 `activeMinutes` 累加
5. `最长沉寂分钟` 取周期内 `longestIdleMinutes` 最大值
6. `最拼一天` 取 `score` 最高的记录
7. `最会摸一天` 取 `moyuScore` 最高的记录

### 5.4 入口与交互

#### 今日战报页

- 在现有今日战报区域中新增 `时间维度切换`
  - `今日`
  - `本周`
  - `本月`
- 当选中 `本周` / `本月` 时，补充显示 `scope` 切换：
  - `进行中`
  - `上一期`
- 预览区直接切换为对应的周期纪念卡
- 操作区保持统一：
  - `复制战报`
  - `保存图片`
- 周期卡第一版不提供 `刷新判词`

#### 历史页

- 保留现有日记录列表不动
- 在列表上方新增轻量纪念卡入口：
  - `生成上周纪念卡`
  - `生成上月纪念卡`
- 历史页第一版不提供任意年月筛选器

### 5.5 状态持久化

- `SettingsStore` 新增：
  - `selectedReportSurface`：`.daily / .weekly / .monthly`
  - `selectedPeriodScope`：`.current / .previousCompleted`
- 打开主窗口时恢复上次选择
- 第一版不保存“某一张周期海报曾使用的历史快照”

### 5.6 渲染与导出

- 新增 `PeriodPosterRenderer`
- 新增 `PosterExportService` 周期导出入口：
  - `generateAndCopyPeriodPoster(kind:scope:)`
  - `generateAndSavePeriodPoster(kind:scope:)`
- 今日页与历史页都通过导出服务生成周期海报，避免各自组装周期逻辑

## 6. 测试范围

新增或更新测试覆盖：

1. `DailyRecordRepositoryTests`
   - 时间范围查询
   - 自然周 / 自然月边界正确性

2. `PeriodReportAggregatorTests`
   - 当前周、上周、当前月、上月的范围计算
   - 跨月 / 跨周边界
   - 空周期处理

3. `PeriodReportComposerTests`
   - 聚合后的核心指标正确
   - 最拼一天 / 最会摸一天选择正确
   - 当前周期文案包含 `截至今日`

4. `PeriodPosterRendererTests`
   - 周报 / 月报都能成功生成 PNG

5. `PosterExportServiceTests`
   - 周期复制 / 保存走新入口
   - 生成的 presentation 与请求 kind / scope 一致

6. `TodayReportViewModelTests`
   - 时间维度切换
   - scope 切换
   - 选择持久化

7. `HistoryViewModelTests`
   - 上周 / 上月纪念卡入口触发导出

## 7. 影响范围

预计修改路径：

- `MoyuCounter/Core/Storage/*`
- `MoyuCounter/Core/Sharing/*`
- `MoyuCounter/Core/Poster/*`
- `MoyuCounter/Core/Settings/SettingsStore.swift`
- `MoyuCounter/Features/Report/*`
- `MoyuCounter/Features/History/*`
- `MoyuCounter/App/AppDependencies.swift`
- 对应 `MoyuCounterTests/*`

## 8. 风险与约束

### 风险 1：周期边界计算出错

控制方式：

1. 把自然周 / 自然月范围计算独立放进聚合层
2. 用固定日历和固定时区写边界测试

### 风险 2：日战报与周期战报 UI 混杂

控制方式：

1. 明确 `selectedReportSurface`
2. 周期视图不强行复用日战报的所有控件

### 风险 3：导出链路重复实现

控制方式：

1. 所有复制 / 保存操作都经由 `PosterExportService`
2. UI 只负责选择 kind / scope，不自己拼装海报

## 9. 验收标准

满足以下条件即视为本轮完成：

1. 今日页可在 `今日 / 本周 / 本月` 间切换
2. 周报 / 月报支持 `进行中 / 上一期`
3. 周期内存在记录时，可稳定复制和保存 PNG
4. 历史页可直接生成 `上周 / 上月纪念卡`
5. 空周期不会报错，而是展示空状态或禁用入口
6. 关闭重开应用后恢复上次时间维度与周期范围选择
7. `swift test` 全量通过
