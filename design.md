# design.md — UI/UX Philosophy & Visual System

## 1. Design Philosophy: "Operational Density with Cognitive Calm"

ALEF's interface serves a user who is simultaneously a developer, a teacher, a freelancer, an investor, and a spiritual practitioner. The design must communicate high-information density without producing decision fatigue.

The visual language is **Dark Utilitarian Precision** — think mission control, not wellness app. Every pixel justifies its existence. Color is semantic, not decorative. Animation is purposeful, not playful.

### Core Tenets
1. **Glanceability First** — The most critical metric in any view must be readable in under 400ms.
2. **Progressive Disclosure** — Summary cards expand to detail. Detail views drill to raw data. Never show everything at once.
3. **Semantic Color System** — Colors mean things and never deviate from their meaning.
4. **Motion as Feedback** — Animations confirm state transitions, not embellish them.

---

## 2. Color & Typography System

### Color Tokens (CSS-style naming for documentation clarity)

```
--bg-primary:      #0A0D12   // Near-black background
--bg-surface:      #111620   // Card/surface layer
--bg-elevated:     #181F2E   // Modals, overlays
--bg-overlay:      #1E2838   // Overlay blocker background

--accent-cyan:     #00D4FF   // Primary interactive / active states
--accent-amber:    #FFB020   // Financial / wealth domain
--accent-emerald:  #00C896   // Health / positive metrics
--accent-violet:   #9B6DFF   // Church / spiritual domain
--accent-red:      #FF4757   // Alerts, blocking states, critical
--accent-slate:    #4A90A4   // Telemetry / neutral data

--text-primary:    #E8EDF5   // Main readable text
--text-secondary:  #7A8A9E   // Labels, descriptions
--text-disabled:   #3A4555   // Muted / inactive

--chart-grid:      #1C2535   // Chart gridlines
--divider:         #1E2838   // Section separators
```

### Typography
- **Display / Hero Numbers:** `JetBrains Mono` — monospaced for numerical data (portfolio value, calorie counts, step numbers). Numbers never reflow.
- **Headings:** `DM Sans` — geometric, authoritative, narrow tracking.
- **Body / Labels:** `DM Sans Regular` — consistent with headings, readable at small sizes.
- **Arabic text** (if ever needed for church content): `IBM Plex Arabic`.

### Type Scale
| Role | Size | Weight | Font |
|---|---|---|---|
| Hero Metric | 48sp | 300 | JetBrains Mono |
| Section Header | 18sp | 600 | DM Sans |
| Card Title | 14sp | 500 | DM Sans |
| Body | 13sp | 400 | DM Sans |
| Label/Caption | 11sp | 400 | DM Sans |
| Monospace Data | 13sp | 400 | JetBrains Mono |

---

## 3. Dashboard Architecture — The Command Center

### Home Dashboard Layout

The home screen is a scrollable **Widget Grid** — not a tab bar. Each domain has a **Snapshot Card** that shows its single most important metric right now.

```
┌────────────────────────────────────────┐
│  ⏱  ALEF           [Date]  [Profile]  │  ← Top bar
├─────────────────────┬──────────────────┤
│  TODAY'S FOCUS      │   HEALTH RING    │  ← Hero row
│  3 tasks pending    │  7,240 steps     │
├─────────────────────┴──────────────────┤
│  ████████████  SCREEN TIME  ─────────  │
│  4h 12m  ▲23% vs yesterday            │
├────────────────────────────────────────┤
│  EGX PORTFOLIO   EARNINGS THIS MONTH   │
│  ↑ +2.4%         EGP 12,400           │
├────────────────────────────────────────┤
│  MASS STREAK     NEXT CONFESSION       │
│  ████░░░ 21d     14 days ago          │
└────────────────────────────────────────┘
```

### Card Component Anatomy
Every Snapshot Card follows the same structure:
1. **Domain accent bar** (2px left border in domain color)
2. **Domain label** (11sp, secondary text)
3. **Hero metric** (48sp monospaced or 24sp DM Sans)
4. **Delta indicator** (directional arrow + percentage change)
5. **Micro-sparkline** (30-day trend, rendered via `fl_chart` `LineChart` with no axes)

Tapping a card performs a **Hero transition** into the full domain dashboard.

---

## 4. fl_chart — Multi-Axis Correlation Dashboards

### Design Principle for Charts
Every chart in ALEF is **cross-domain capable**. The user should be able to overlay:
- Freelance earnings (amber line) on the same time axis as
- EGX portfolio value (cyan line) and
- Daily calorie surplus/deficit (emerald/red bars)

This correlation view answers the question: *"Was I eating worse during my high-stress earning periods?"*

### Chart Specifications

#### 4.1 — Financial Overview Chart (`LineChart` + `BarChart` composite)
```
X-axis: Time (days/weeks/months — toggle)
Y-axis Left: EGP value (portfolio + cash)
Y-axis Right: Caloric balance (kcal surplus/deficit)
Overlay Lines:
  - Portfolio value: solid cyan, 2px stroke
  - Monthly earnings: dashed amber, 2px stroke
  - Running expense total: dotted red, 1px stroke
Background Bars:
  - Daily caloric balance: emerald (surplus) / red (deficit) bars, 40% opacity
Grid: Horizontal only, #1C2535 (--chart-grid), 1px
Tooltip: Custom tooltip showing all 4 values at touched X position
```

**Implementation pattern:**
```dart
LineChartData(
  lineBarsData: [portfolioLine, earningsLine, expenseLine],
  titlesData: FlTitlesData(
    leftTitles: AxisTitles(sideTitles: egpTitles),
    rightTitles: AxisTitles(sideTitles: kcalTitles),
    bottomTitles: AxisTitles(sideTitles: dateTitles),
  ),
  lineTouchData: LineTouchData(
    touchTooltipData: LineTouchTooltipData(
      tooltipBgColor: Color(0xFF1E2838),
      getTooltipItems: multiAxisTooltipBuilder,
    ),
  ),
)
```

#### 4.2 — Health Dashboard (`BarChart` + `RadarChart`)
- **Weekly Steps Bar Chart:** 7 bars (Mon–Sun), emerald fill, today's bar highlighted with cyan outline
- **Sleep Stage Radar:** 4 axes (Deep, REM, Light, Awake), violet fill at 60% opacity, comparing this week vs last week
- **Heart Rate Trend:** `LineChart` with 24h granularity, gradient fill from `--accent-emerald` to transparent

#### 4.3 — Telemetry Dashboard (`PieChart` + `BarChart`)
- **App Usage Pie:** Top 8 apps by screen time, each with a unique tinted slice
- **Hourly Activity Heatmap:** Custom `Canvas`-painted grid (7 days × 24 hours), color intensity = unlock frequency
- **Decision Break Stats:** `BarChart` showing how many times each blacklisted app was blocked vs. allowed per day

#### 4.4 — Mass Attendance Streak Grid
A custom `CustomPainter` implementation (not fl_chart) rendering a GitHub-style contribution grid:
- 52 columns (weeks) × 7 rows (days)
- Cell color: `--accent-violet` at opacity tiers (0%, 30%, 70%, 100%) based on attendance type
- Longest streak highlighted with a cyan underline annotation

---

## 5. Animation Strategy

### Guiding Rule: "Animate State, Not Content"

Animations exist to communicate *that something changed* and *what the new state is*. They do not exist to entertain.

### Animation Inventory

| Trigger | Animation | Duration | Curve |
|---|---|---|---|
| App launch | Staggered card reveal (cards slide in from bottom, 80ms apart) | 400ms total | `Curves.easeOutCubic` |
| Card tap → domain view | Hero expand + fade content in | 300ms | `Curves.fastOutSlowIn` |
| Metric value change | Countup tween (number animates from old to new value) | 600ms | `Curves.easeOutExpo` |
| Task completion | Strikethrough draw + card collapses | 250ms | `Curves.easeInOut` |
| Overlay blocker appear | Scale from 0.95 + fade in (jarring, intentional) | 150ms | `Curves.easeOut` |
| Decision break countdown | Circular progress ring draining | Real-time | Linear |
| BLoC loading state | Shimmer scan across card skeleton | Loop | Linear |
| Chart data load | Lines draw from left to right | 500ms | `Curves.easeOutQuart` |
| Voice listening | Pulsing waveform (Rive animation or `AnimationController` + `CustomPainter`) | Loop | Sine wave |

### Rive Integration (Voice & Overlay)
Two Rive animations are used for states that require fluid, continuous motion:
1. **Voice Listener State Machine:** Idle → Listening → Processing → Done. Artboard shows a minimal waveform that responds to audio amplitude (driven by amplitude data streamed from the wake-word engine).
2. **Decision Break Overlay:** A bold countdown ring with an ambient particle drift behind the timer number — communicates "pause, don't panic."

### Micro-Interaction Details
- **Toggle switches** use a custom thumb that morphs shape (circle → rounded square when toggled on) — 200ms
- **Chart touch** highlights the touched point with a pulse ring expand — 300ms, no repeat
- **Bottom sheet expansion** uses a custom `DraggableScrollableSheet` with spring physics simulation

---

## 6. Navigation Architecture

### Structure
```
MaterialApp
├── DashboardShell (persistent bottom nav, 5 tabs)
│   ├── Tab 0: Home (Command Center)
│   ├── Tab 1: Productivity (Tasks + Calendar)
│   ├── Tab 2: Health (Biometrics + Nutrition)
│   ├── Tab 3: Finance (Ledger + EGX)
│   └── Tab 4: Church (Attendance + Ministry)
├── TelemetryOverview (floating action button → full screen)
├── SettingsFlow (pushed on top)
└── VoiceCommandSheet (bottom sheet, triggered by wake word or mic FAB)
```

### Bottom Navigation
- **No labels** — domain identified by icon + accent color only
- Active tab: icon fills with domain accent color, scale 1.15
- Inactive: icon outline in `--text-disabled`
- Tab switch animation: icon morphs using `AnimatedIcon` where available, else crossfade

### Adaptive Layout (Android vs Windows)
- **Android:** Single-column scroll, bottom navigation bar
- **Windows:** Two-column layout with persistent left rail navigation, chart views expand to fill available horizontal space, keyboard shortcuts for all primary actions