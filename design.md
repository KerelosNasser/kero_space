# design.md — UI/UX Philosophy & Visual System

![Kero Space Logo](file:///C:/Users/keron/.gemini/antigravity-ide/brain/2dfa2d70-6002-4d06-ae89-d67797c2b90e/kero_space_minimal_logo_1780785663495.png)

## 1. Design Philosophy: "Minimalist Apple Aesthetic"

Kero Space's interface serves a user who is simultaneously a developer, a teacher, a freelancer, an investor, and a spiritual practitioner. The design must communicate high-information density while feeling as native and frictionless as an iOS app.

The visual language is **Monochrome Minimalism** — pure black backgrounds, high-contrast white typography, and standard iOS native components. Color is used sparingly, primarily relying on black, white, and subtle grays.

### Core Tenets
1. **OLED Black First** — The primary background is pure `#000000` to create a seamless, borderless feel on modern screens.
2. **High Contrast** — White is the primary secondary color, used for text, essential icons, and primary interactions.
3. **Cupertino Native** — Utilize iOS design patterns: large titles, subtle blurs, bottom sheets, and native spring animations.
4. **Motion as Feedback** — Fluid, physics-based spring animations that feel distinctly Apple.

---

## 2. Color & Typography System

### Color Tokens (iOS Dark Mode style)

```
--bg-primary:      #000000   // Pure Black (OLED native)
--bg-surface:      #1C1C1E   // Cupertino Secondary System Background
--bg-elevated:     #2C2C2E   // Cupertino Tertiary System Background
--bg-overlay:      rgba(0, 0, 0, 0.6) // Cupertino Modal Backdrop (with high blur)

--accent-primary:  #FFFFFF   // Pure White (primary actions, active states)
--accent-cyan:     #0A84FF   // iOS System Blue (links, primary buttons)
--accent-mint:     #32D74B   // iOS System Green (success, health, rings)
--accent-rose:     #FF453A   // iOS System Red (destructive actions, errors)
--accent-gold:     #FF9F0A   // iOS System Orange (alerts, warnings)
--accent-violet:   #BF5AF2   // iOS System Purple (spirituality, church)

--text-primary:    #FFFFFF   // Pure White
--text-secondary:  rgba(235, 235, 245, 0.6) // iOS Secondary Label Color
--text-disabled:   rgba(235, 235, 245, 0.3) // iOS Tertiary Label Color

--glass-border:    rgba(255, 255, 255, 0.15) // Hairline separator
--border-glow:     rgba(255, 255, 255, 0.12) // White focus glow
--chart-grid:      #38383A   // iOS System Separator Color
--divider:         #38383A   // Clean horizontal rule divider
```

### Typography
- **Display / Hero Numbers:** `SF Pro Display` — Apple's system font, rounded and clean. `SF Rounded` or `SF Mono` for data where appropriate.
- **Headings:** `SF Pro Display` — bold, tight tracking.
- **Body / Labels:** `SF Pro Text` — highly readable at small sizes.
- **Arabic text** (if ever needed for church content): `SF Arabic`.

### Type Scale (iOS Human Interface Guidelines)
| Role | Size | Weight | Font |
|---|---|---|---|
| Large Title | 34sp | 700 | SF Pro Display |
| Title 1 | 28sp | 600 | SF Pro Display |
| Title 2 | 22sp | 600 | SF Pro Display |
| Headline | 17sp | 600 | SF Pro Text |
| Body | 17sp | 400 | SF Pro Text |
| Footnote | 13sp | 400 | SF Pro Text |

### Implementation Guidelines
- **Single-File Theming:** To simplify code edits and ensure uniform branding, all color variables, HSL values, visual decoration constants, and text stylings are declared strictly in a single source file: `lib/core/app_theme.dart`.
- **Shared Component Directory:** All refactored, reusable widget components (e.g., custom cards, input text-fields, loading states, standard buttons, charts) must reside in a single directory: `lib/shared/widgets/`. Feature-specific widgets must be placed locally only if they cannot be generalized.

---

## 3. Dashboard Architecture — The Command Center

### Home Dashboard Layout

The home screen is a scrollable **Widget Grid** — not a tab bar. Each domain has a **Snapshot Card** that shows its single most important metric right now.

```
┌────────────────────────────────────────┐
│  ⏱  KERO SPACE      [Date]  [Profile]  │  ← Top bar
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
1. **Domain accent bar** (2px left border in domain color or pure white)
2. **Domain label** (11sp, secondary text)
3. **Hero metric** (34sp SF Pro Display)
4. **Delta indicator** (directional arrow + percentage change)
5. **Micro-sparkline** (30-day trend, rendered via `fl_chart` `LineChart` with no axes)

Tapping a card performs a **Hero transition** into the full domain dashboard.

### 3.3 — The Omniscient Control Center UI (Blocker Tuning Interface)
The Omniscient Control Center acts as the operational dashboard for adjusting app telemetry and blockers, designed to manage ADHD-driven impulsivity with immediate, granular control.

```
┌────────────────────────────────────────┐
│  ⚙  OMNISCIENT CONTROL        [Active] │  ← Settings header
├────────────────────────────────────────┤
│  BACKGROUND AGENTS STATUS              │
│  ┌──────────────────┬──────────────────┐│
│  │ ACCESSIBILITY    │ USAGE GUARD      ││  ← 2x2 toggle grid
│  │ 🟢 Active        │ 🟢 Active        ││    shows live status
│  ├──────────────────┼──────────────────┤│
│  │ SCREEN LOG       │ WAKE WORD        ││
│  │ 🔴 Stopped       │ 🟢 Active        ││
│  └──────────────────┴──────────────────┘│
├────────────────────────────────────────┤
│  APP BLOCKERS & BLACKLIST              │
│  - Instagram    [ 1h 30m / 2h ]  ⚙      │  ← Usage limits
│  - TikTok       [ Locked (Hard) ] ⚙    │  ← Custom strictness
│  - YouTube      [ 30m / 45m ]    ⚙     │
│  [+] Add App to Blocklist               │  ← App selection FAB
├────────────────────────────────────────┤
│  GLOBAL BLOCKER STRICTNESS             │
│  Strictness Level: [ Hard Lockout ]    │  ← Hard Lockout prevents bypass
│  Allowed Hours:    08:00 - 22:00       │  ← Hour wheel pickers
│  Decision Break:   [ 30 seconds ]      │  ← Countdown length slider
└────────────────────────────────────────┘
```
1. **Live Diagnostics Cards:** Compact state grid indicating if each background service is alive (Accessibility, UsageStats, ScreenReceiver, WakeWord), displaying real-time memory load (e.g., `<2% battery/hr`).
2. **Dynamic Blacklist Configuration:** Tap on any blacklisted app to edit details:
   - **Allowed Duration limit:** Time input dial.
   - **Decision Break duration:** Slider from 5s to 120s.
   - **Strictness Tier:** *Soft Break* (allows entry after custom countdown reflection task) vs. *Hard Lockout* (disables app for remainder of the calendar day).
3. **Emergency Bypass Interface:** Requires typing a random 12-character alphabetic sequence or completing a rapid logic puzzle to discourage mindless overriding. All overrides log context data.

### 3.4 — Coptic Orthodox Fasting Calendar Display & Macros
Integrates visual alerts for yearly shifting fasting periods (Great Lent, Advent, Jonah's Fast, Apostles' Fast, Wednesdays and Fridays).

1. **Calendar Visual Anchors:**
   - **Fasting Day Indicator:** Calendar grid dates flagged with a subtle violet radial under-glow or border (`--accent-violet`).
   - **Fasting Type Badge:** Selecting a date shows a details panel with badges like `[FAST: Great Lent]` or `[FAST: Apostles' Fast]`.
   - **Alexandrian Computus Banner:** A top banner displays during active seasons indicating fasting progress (e.g., "Great Lent — Day 15 of 55").
2. **Health Macro & DB Fasting Integration:**
   - **Fasting Mode Toggle:** Global switch in the Nutrition view. Toggling shifts the macro goals dynamically (increasing complex carbs, reducing proteins/fats to vegan ratios).
   - **Egyptian Food Filter:** Highlights vegan local items (e.g., Ful Medames, Koshary, Ta'ameya) and flags prohibited ingredients (meat, dairy, eggs, fish) in red inside the ingredient logger.

### 3.5 — ADHD Cognitive Flow & Gamification Systems
Minimizes cognitive friction while offering positive reinforcement loops to support focus.

1. **Active Focus Widget (Visual Anchor):**
   - Pin a single task to the top hero row. The pinned card pulsates with a slow, breathing white/gray gradient to ground wandering attention without breaking the monochrome aesthetic.
2. **Gamified Dopamine Milestones:**
   - **Task Slash Spell:** Completing a task triggers a crisp haptic tap (`HapticFeedback.lightImpact`) and draws a neon slash across the card text. A micro-particle burst (using custom Canvas painting) sprays small colored shapes outwards.
   - **Streak Counters:** Top bar features flame icons displaying continuous healthy habits (fasting compliance, daily focus streaks, liturgy attendance).
3. **Frictional Postponement:**
   - Swipe actions: Quick right-swipe to check off. Dragging left to postpone triggers a springy, high-friction drag feel (`Curves.elasticOut` response) and prompts the user to input a 3-word reason for delaying, making procrastination conscious.

---

## 4. fl_chart — Multi-Axis Correlation Dashboards

### Design Principle for Charts
Every chart in Kero Space is **cross-domain capable**. The user should be able to overlay:
- Freelance earnings (gold line) on the same time axis as
- EGX portfolio value (cyan line) and
- Daily calorie surplus/deficit (mint/rose bars)

This correlation view answers the question: *"Was I eating worse during my high-stress earning periods?"*

### Chart Specifications

#### 4.1 — Financial Overview Chart (`LineChart` + `BarChart` composite)
```
X-axis: Time (days/weeks/months — toggle)
Y-axis Left: EGP value (portfolio + cash)
Y-axis Right: Caloric balance (kcal surplus/deficit)
Overlay Lines:
  - Portfolio value: solid cyan, 2px stroke
  - Monthly earnings: dashed gold, 2px stroke
  - Running expense total: dotted rose, 1px stroke
Background Bars:
  - Daily caloric balance: mint (surplus) / rose (deficit) bars, 40% opacity
Grid: Horizontal only, #38383A (--chart-grid), 1px
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
      tooltipBgColor: Color(0xFF121722),
      getTooltipItems: multiAxisTooltipBuilder,
    ),
  ),
)
```

#### 4.2 — Health Dashboard (`BarChart` + `RadarChart`)
- **Weekly Steps Bar Chart:** 7 bars (Mon–Sun), mint fill, today's bar highlighted with cyan outline
- **Sleep Stage Radar:** 4 axes (Deep, REM, Light, Awake), violet fill at 60% opacity, comparing this week vs last week
- **Heart Rate Trend:** `LineChart` with 24h granularity, gradient fill from `--accent-mint` to transparent

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
| App launch | Native modal slide up or fade | 300ms | `Curves.easeOut` (or iOS Spring) |
| Card tap → domain view | Cupertino page transition | 350ms | iOS Spring (fast out, slow in) |
| Metric value change | Countup tween (number animates from old to new value) | 500ms | `Curves.easeOutExpo` |
| Task completion | Checkmark morph + row collapse | 300ms | iOS Spring |
| Overlay blocker appear | Modal presentation slide up | 350ms | iOS Spring |
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