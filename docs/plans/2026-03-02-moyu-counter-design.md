# Moyu Counter Product Design

## 1) Product Snapshot

- Product name: `Moyu Counter` (macOS menu bar desktop app)
- Product type: light-weight productivity entertainment tool
- Target users: office workers and students who want fun self-tracking
- Core value: convert keyboard/mouse activity into humorous daily feedback
- Product tone: playful, not a strict attendance monitor

## 2) Confirmed Scope

- Platform: native macOS app (`SwiftUI` + menu bar mode)
- Time scope: switchable between `Work Hours Only` and `Whole Day`
- Data policy: local-only storage (no cloud sync in MVP)
- Poster generation: local template-based poster first, AI-generated poster later

## 3) Goals and Non-Goals

### Goals (MVP)

1. User can set work start/end time in under 3 minutes.
2. App can collect keyboard/mouse usage frequency per minute.
3. App can produce a daily score and a category label.
4. App can export one humorous poster per day from templates.
5. App works fully offline after install.

### Non-Goals (MVP)

1. No employee monitoring dashboard.
2. No team ranking or social leaderboard.
3. No cloud account system.
4. No AI image generation in v1.

## 4) Functional Requirements

### FR-01 Setup and Preferences

- User can set:
  - work start time
  - work end time
  - tracking scope (`Work Hours Only` / `Whole Day`)
- User can update settings at any time.

### FR-02 Input Activity Collection

- Track keyboard and mouse activity as counts, not content.
- Aggregate to 1-minute buckets.
- Support app relaunch and continue collecting in current day.

### FR-03 Daily Scoring

- At day-end (or manual trigger), compute daily score in range `0-100`.
- Produce:
  - score
  - level label
  - one short text line

### FR-04 Humorous Poster

- Generate one poster based on score range:
  - `NiuMa` style (high activity)
  - `Moyu Master` style (low activity)
  - neutral style (middle)
- User can save image or copy image.

### FR-05 Menu Bar Experience

- Menu bar icon shows app status.
- Dropdown shows:
  - current mode
  - today's quick stats
  - generate poster action
  - open settings

### FR-06 Local History

- Store and show last 30 days:
  - score
  - level
  - active minutes

## 5) Scoring Model v1

Use explainable rule-based scoring first.

### Inputs

- `EPM`: events per minute (keyboard + mouse)
- `LowActiveMinutes`: minutes where `EPM < L`
- `HighActiveMinutes`: minutes where `EPM >= H`
- `TrackedMinutes`: total tracked minutes in selected scope
- `LongestIdleRun`: longest continuous low-activity run

Suggested thresholds:

- `L = 2`
- `H = 15`

### Derived Ratios

- `low_ratio = LowActiveMinutes / TrackedMinutes`
- `high_ratio = HighActiveMinutes / TrackedMinutes`
- `idle_ratio = LongestIdleRun / TrackedMinutes`

### Score Formula

`labor_score = clamp(0, 100, round(100 * (0.55 * high_ratio + 0.25 * (1 - low_ratio) + 0.20 * (1 - idle_ratio))))`

`moyu_score = 100 - labor_score`

### Labels

- `labor_score >= 75`: `Top NiuMa`
- `45 <= labor_score < 75`: `Balanced Human`
- `labor_score < 45`: `Moyu Master`

### Copy Text Template

- `Top NiuMa`: "Keyboard has smoke, mouse has sparks."
- `Balanced Human`: "Work and fish are in dynamic balance."
- `Moyu Master`: "Your fish escaped and came back with friends."

## 6) UX Information Architecture

## 6.1 Navigation Map

- `MenuBar Root`
  - `Today Snapshot`
  - `Mode Toggle`
  - `Generate Today's Poster`
  - `History (Last 30 Days)`
  - `Settings`
  - `Quit`

## 6.2 Key Screens

1. `First Run Permission View`
   - explain what data is collected
   - request accessibility/input monitoring permission
2. `Menu Dropdown`
   - compact daily stats and quick actions
3. `Settings Window`
   - work hours, scope toggle, reset data
4. `Daily Result Sheet`
   - score, label, text line, poster preview, save/copy
5. `History Window`
   - simple list + 7-day trend

## 6.3 Interaction Flow

1. User installs and launches app.
2. User grants required permission.
3. User sets work schedule and tracking mode.
4. App passively tracks activity.
5. Day end trigger computes score.
6. User opens daily result and exports poster.

## 7) Technical Design

- UI layer: `SwiftUI` + `MenuBarExtra`
- Event collection: Quartz event tap / AppKit hooks
- Scheduler: timer + day boundary job
- Storage: local SQLite (single file)
- Poster rendering: local assets + CoreGraphics compositing

### Proposed module layout

- `MoyuCounter/App/`
- `MoyuCounter/Features/MenuBar/`
- `MoyuCounter/Features/Settings/`
- `MoyuCounter/Features/History/`
- `MoyuCounter/Core/ActivityCollector/`
- `MoyuCounter/Core/Scoring/`
- `MoyuCounter/Core/Storage/`
- `MoyuCounter/Core/Poster/`
- `MoyuCounter/Core/Scheduler/`

## 8) Privacy and Compliance

- Collect only event counts; never log key text or clipboard data.
- Keep all records local; no network transfer in MVP.
- Provide clear reset and delete-all-data option.
- Add plain-language permission explanation before OS prompt.

## 9) Risks and Mitigations

1. Permission denied:
   - show retry guide and degraded mode warning.
2. Inaccurate score perception:
   - expose formula and threshold in settings tooltip.
3. Energy impact:
   - use minute-bucket aggregation and avoid heavy realtime redraw.
4. False positives from passive mouse movement:
   - weight keyboard events higher in v1.1 if needed.

## 10) Milestones and Timeline

### Week 1: Foundation

- Menu bar app shell
- permission onboarding
- activity collection + minute aggregation

### Week 2: Core Loop

- scoring engine v1
- day-end settlement
- template poster generation

### Week 3: Polish and Beta

- 30-day history
- UX copy and edge-case handling
- packaging and internal beta

## 11) Acceptance Criteria

1. First-time setup can be completed in under 3 minutes.
2. Daily score and poster are generated reliably offline.
3. User can switch scope mode without app restart.
4. Data reset removes all local history immediately.
