# Pillar — Design System

> Visual language, motion grammar, component catalogue, and accessibility
> contract for every user-facing surface. This file is the *how* at the
> user-facing level.

---

## 1. Visual Philosophy

**"Calm instrument."** Kero is a private dashboard, not a social feed.
The aesthetic borrows from high-end audio gear (Teenage Engineering,
Braun), medical instrumentation (Withings, OMROM), and Coptic iconography
(geometric, gold-accented, never garish). The product is dense with data
and yet quiet on the eye.

### 1.1 Three rules

1. **One accent per screen.** Charts may use the data palette; everything
   else uses a single foreground accent.
2. **No drop shadows on data.** Shadows are reserved for floating surfaces
   (FAB, modal sheets). Charts use stroke weight, not depth.
3. **Negative space is data.** Whitespace groups and prioritises; we never
   fill a viewport for the sake of filling it.

### 1.2 Anti-patterns (rejected at review)

- Neon-on-black "trader dashboards".
- Stock photos of sunsets/sandals.
- Glassmorphism over charts (kills legibility).
- Gradients used for decoration rather than to convey state.
- Confetti, fireworks, bouncing emojis.

---

## 2. Color System

### 2.1 Dark theme (default)

| Token             | Hex       | Usage                                         |
| ----------------- | --------- | --------------------------------------------- |
| `surface.0`       | `#0E1116` | App background                                |
| `surface.1`       | `#161A22` | Cards, list rows                              |
| `surface.2`       | `#1F2530` | Elevated surfaces (sheets, popovers)          |
| `surface.3`       | `#2A3140` | Hover/pressed states                          |
| `border.subtle`   | `#2A3140` | 1px dividers                                  |
| `border.strong`   | `#3A4252` | 2px focus, section breaks                     |
| `text.primary`    | `#E6EAF2` | Body                                          |
| `text.secondary`  | `#9AA3B2` | Captions, metadata                            |
| `text.muted`      | `#5E6675` | Disabled                                      |
| `accent.kero`     | `#C8A24A` | Primary accent (Kero gold, Coptic-inspired)   |
| `accent.kero.dim` | `#8A6E2C` | Accent on dark surfaces                       |
| `semantic.good`   | `#3DBA86` | Streak kept, budget under, gain               |
| `semantic.warn`   | `#E0A93B` | Approaching threshold                         |
| `semantic.bad`    | `#D85060` | Over budget, streak broken, loss              |
| `data.series.1`   | `#7AA2F7` | Earnings                                      |
| `data.series.2`   | `#9ECE6A` | Steps                                         |
| `data.series.3`   | `#E0A93B` | Screen time                                   |
| `data.series.4`   | `#BB9AF7` | Mass attendance                               |
| `data.series.5`   | `#7DCFFF` | EGX portfolio                                 |
| `data.series.6`   | `#F7768E` | Calories                                      |

### 2.2 Light theme

| Token             | Hex       |
| ----------------- | --------- |
| `surface.0`       | `#FAF7F0` |  (warm off-white, parchment-inspired) |
| `surface.1`       | `#FFFFFF` |
| `surface.2`       | `#F2EEE4` |
| `surface.3`       | `#E5DFD0` |
| `border.subtle`   | `#E5DFD0` |
| `border.strong`   | `#C8C0AB` |
| `text.primary`    | `#1A1A1A` |
| `text.secondary`  | `#5C5648` |
| `text.muted`      | `#8A8474` |
| `accent.kero`     | `#8A6E2C` |
| `accent.kero.dim` | `#C8A24A` |

Semantic and data colors are identical to dark; only surface/text differ.
The parchment background is a 1-dB nudge toward warmth — it reduces
blue-light fatigue during late-evening reviews.

### 2.3 Colour-blind safety

* All semantic states have a non-color cue: a leading icon and a textual
  label.
* Charts pair color with a unique line dash pattern (defined per series).
* The 6-color data palette is verified to be distinguishable for the three
  common forms of CVD (deuteranopia, protanopia, tritanopia) via the
  `colorblind` simulator in the design QA suite.

---

## 3. Typography

We use **Inter** for UI text and **JetBrains Mono** for numeric / tabular
content. Both are OFL and bundled in the app to avoid network fetches.

| Role             | Family          | Size / Weight / Line-height               |
| ---------------- | --------------- | ----------------------------------------- |
| `display.l`      | Inter           | 40 / 600 / 48                             |
| `display.m`      | Inter           | 28 / 600 / 36                             |
| `title.l`        | Inter           | 22 / 600 / 28                             |
| `title.m`        | Inter           | 18 / 600 / 24                             |
| `body.l`         | Inter           | 16 / 400 / 24                             |
| `body.m`         | Inter           | 14 / 400 / 20                             |
| `caption`        | Inter           | 12 / 500 / 16                             |
| `overline`       | Inter           | 10 / 600 / 14, +0.08em tracking, UPPER     |
| `numeric.xl`     | JetBrains Mono  | 32 / 500 / 36, `tabular-nums`             |
| `numeric.l`      | JetBrains Mono  | 20 / 500 / 24, `tabular-nums`             |
| `numeric.m`      | JetBrains Mono  | 14 / 500 / 20, `tabular-nums`             |

Tabular figures are mandatory in any column of numbers. Proportional
figures are used in body prose.

---

## 4. Spacing & Layout

### 4.1 Spacing scale (4-pt grid)

`4, 8, 12, 16, 20, 24, 32, 40, 56, 72, 96`

Use the named tokens: `space.xs` (4), `space.s` (8), `space.m` (12),
`space.l` (16), `space.xl` (20), `space.2xl` (24), `space.3xl` (32),
`space.4xl` (40), `space.5xl` (56), `space.6xl` (72), `space.7xl` (96).

### 4.2 Layout

* **Phone**: single column, max content width 600 dp, side gutters 16 dp.
* **Tablet (≥ 720 dp)**: two-column "rail + content" with persistent
  navigation rail on the left.
* **Windows desktop (≥ 960 dp)**: three-pane layout — `Sidebar` (240 dp)
  + `Content` (fluid) + `Inspector` (320 dp, collapsible). Inspector is
  context-aware (e.g. opens on row click in ledger).

### 4.3 Touch targets

* Minimum 48 × 48 dp on touch, 32 × 32 dp on pointer.
* Pointer hover states on Windows are mandatory for any actionable element.

---

## 5. Motion Grammar

### 5.1 Principles

1. **Interruptible.** Any animation can be cancelled by a new input; the
   state resolves to the new target, never to an in-between.
2. **Bounded.** No animation exceeds 400 ms except page-route transitions
   (≤ 320 ms).
3. **Reduced-motion respected.** When the system reports
   `prefers-reduced-motion`, all transforms are replaced with opacity
   crossfades, and chart updates skip the interpolation step.
4. **Choreographed, not orchestrated.** A staggered list enters with
   24 ms × index delay, capped at 5 elements. We never stagger 50 cards.

### 5.2 Durations

| Token             | ms  | Usage                                                |
| ----------------- | --- | ---------------------------------------------------- |
| `dur.instant`     | 80  | State flips (toggle, checkbox)                       |
| `dur.fast`        | 160 | Hover, focus, ripple                                 |
| `dur.standard`    | 240 | Modal rise, sheet slide, FAB morph                   |
| `dur.slow`        | 320 | Page route, chart axis reveal                        |
| `dur.slowest`     | 480 | Rive state-machine transitions only                  |

### 5.3 Easings

| Token             | Curve                                                | Usage                       |
| ----------------- | ---------------------------------------------------- | --------------------------- |
| `ease.standard`   | `cubic-bezier(0.2, 0, 0, 1)`                         | Default                     |
| `ease.emphasized` | `cubic-bezier(0.2, 0, 0, 1)` (decel only)             | Enter from below            |
| `ease.exit`       | `cubic-bezier(0.4, 0, 1, 1)` (accel only)            | Exit to above               |
| `ease.spring`     | Custom `Spring` with `stiffness 180, damping 22`     | Rive / mascot interactions  |
| `ease.linear`     | `linear`                                             | Indeterminate progress only |

### 5.4 Chart-specific motion

* `fl_chart` is configured with `duration: 240 ms` for all data updates.
* A line chart with 10 000 points uses `LineChart`'s built-in viewport
  with `clipData: FlClipData.all()` to keep the canvas paint bounded.
* Pan and zoom use Flutter's `InteractiveViewer`-style gestures baked
  into `fl_chart`'s `LineTouchData`; no custom gesture recogniser.

### 5.5 Rive state machines

* `mascot.riv` — Kero bird (Coptic iconography: geometric, gold-bordered)
  with states: `idle`, `listening`, `thinking`, `celebrating`, `resting`.
  Triggered by the Omniscient Layer's wake-word engine.
* `streak_grid.riv` — 30-day grid; each cell has states `empty`,
  `kept`, `missed`, `future`. Tied to the Spiritual pillar's `streaks`
  collection.
* `decision_shield.riv` — full-screen overlay with a slow radial breathing
  animation (0.06 Hz) during the Decision Break countdown.

---

## 6. Component Catalogue

The design system ships as `package:kero_design` and exposes:

### 6.1 Primitives

| Component           | Notes                                                                   |
| ------------------- | ----------------------------------------------------------------------- |
| `KeroScaffold`      | Wraps `Scaffold`; injects theme, locale, accessibility scale.           |
| `KeroCard`          | Surface.1 background, 12 dp radius, 1 px subtle border.                  |
| `KeroSection`       | Title + optional action + child. Vertical rhythm 16 dp.                 |
| `KeroButton`        | Three intents: `primary`, `secondary`, `tertiary`. One icon slot.       |
| `KeroIconButton`    | 40 × 40 dp, tooltip-mandatory, focus ring 2 dp.                         |
| `KeroTextField`     | 48 dp height, floating label, error in `semantic.bad`, mono mode.       |
| `KeroChip`          | 24 dp height, selectable, with optional leading dot.                    |
| `KeroSwitch`        | 52 × 32 dp; haptic on toggle.                                           |
| `KeroSlider`        | 200 dp min, snap points supported, live value tooltip.                  |
| `KeroSegmented`     | 2–4 options, spring-driven selection.                                   |
| `KeroBottomSheet`   | `showModalBottomSheet` wrapper; 24 dp top radius, drag handle.          |
| `KeroDialog`        | `Dialog` with `surface.2`, max 480 dp wide.                             |
| `KeroTooltip`       | 250 ms hover delay; arrow; never on chart data points (use marker).     |
| `KeroToast`         | 3 s; bottom-anchored; action slot.                                      |
| `KeroEmptyState`    | 240 × 240 illustration + title + body + primary CTA.                   |
| `KeroErrorState`    | Same as empty + "Copy diagnostics" CTA.                                |
| `KeroSkeleton`      | Shimmer disabled by default; static surface.2 block.                   |

### 6.2 Composed

| Component           | Notes                                                                   |
| ------------------- | ----------------------------------------------------------------------- |
| `KeroStatTile`      | Title + `numeric.l` value + delta arrow + sparkline.                    |
| `KeroTimeSeries`    | Wraps `fl_chart.LineChart`; tooltip, brush, zoom.                       |
| `KeroBarSeries`     | Wraps `fl_chart.BarChart`; stacking + per-bar action.                   |
| `KeroHeatMap`       | Calendar heatmap (28-day or 365-day).                                   |
| `KeroStreakGrid`    | Rive-backed; binds to a `streaks` stream.                              |
| `KeroLedgerRow`     | Debit / credit / currency-aware, mono numerals, two-line meta.          |
| `KeroMoneyInput`    | `KeroTextField` with `MoneyTextInputFormatter`, currency dropdown.      |
| `KeroMassBadge`     | Sunday-pill, streak-aware.                                              |
| `KeroFocusShield`   | Rive-backed full-screen blocker (used by Decision Break).               |
| `KeroVoiceSheet`    | Bottom sheet with Rive mascot + live transcript.                        |

### 6.3 Pillar-specific screens (signature)

| Screen              | Signature elements                                                  |
| ------------------- | ------------------------------------------------------------------- |
| **Today**           | Time-aware greeting, top 3 priorities, today's Mass, today's spend |
| **Focus**           | Decision Break settings, app blacklist editor, today-by-the-hour    |
| **Ledger**          | Three-pane (accounts / journal / inspector), running balance chart  |
| **EGX**             | Holdings table, sector donut, performance ribbon, dividend calendar |
| **Body**            | Macro ring, meal log timeline, wearable vitals strip                |
| **Sanctuary**       | Streak grid, ministry kanban, encrypted confessional entry         |
| **Insights**        | Cross-pillar "Week in Review" with correlation scatter              |

---

## 7. Dashboard Aesthetic (Analytics Pillar)

### 7.1 Information density

* **Per-screen budget**: ≤ 6 distinct chart surfaces, ≤ 4 active filters,
  ≤ 1 hero number.
* **Chart canvas height**: 200 dp on phone, 280 dp on tablet, 320 dp on
  Windows.
* **Axis labels**: 8 dp caption size, 50 % opacity, never italic.

### 7.2 Interactions

| Gesture         | Effect                                                |
| --------------- | ----------------------------------------------------- |
| Tap data point  | Inspector opens with full row context                 |
| Long-press      | Pin annotation; crosshair mode                        |
| Pinch           | Zoom X axis (preserves Y range)                       |
| Pan X           | Scroll viewport                                       |
| Two-finger pan  | Pan both axes (rare; Windows trackpad only)           |
| Hover (Windows) | Tooltip with virtualized row link                     |

### 7.3 Cross-axis correlation

* The Insights screen uses a **scatter** with `fl_chart.ScatterChart` and
  a selectable X variable (steps, sleep, screen time, mood) vs selectable
  Y variable (productivity score, spend, mood). Pearson r is shown in the
  Inspector; a regression line overlays in `data.series.1` with 1-px
  stroke.

### 7.4 Empty / loading / error

* **Loading**: chart skeleton with `dur.standard` opacity pulse (NOT a
  shimmer — the brief forbids theatrical motion).
* **Empty**: honest copy ("No EGX holdings yet. Add a lot to begin.") +
  a single CTA.
* **Error**: copy + "Retry" + "Copy diagnostics". Never a stack trace
  on the surface.

---

## 8. Accessibility

### 8.1 Targets

* **WCAG 2.2 AA** on the six primary screens and every Composed component.
* **Color contrast**: ≥ 4.5:1 for body text, ≥ 3:1 for ≥ 18-pt text and
  any non-text UI element.
* **Focus order**: matches reading order; never tabs through invisible
  items.
* **Hit area**: every interactive element has a 48 × 48 dp hit area on
  touch (we expand the hit area, not the visual).
* **Screen reader**: every chart has a hidden semantic summary
  ("Steps: 8,420, 12 % above 7-day average."). Tooltips are not the
  source of truth.

### 8.2 Motion sensitivity

* Global `KeroMotionScope` watches the system setting. When reduced
  motion is requested, all `dur.standard` and above collapse to 0 ms;
  Rive animations fall back to the first frame; chart updates become
  instant.

### 8.3 Dynamic type

* The text scale factor follows the system setting, clamped to `[0.85,
  1.4]`. Beyond 1.4 the layout reflows to two columns where possible.
* Chart numeric labels are pinned to fixed sizes; only titles and
  captions scale.

### 8.4 Internationalisation

* English (en) and Modern Standard Arabic (ar) at v1.0. RTL is
  first-class: every layout is RTL-tested, not retrofitted.
* Date/number formatting uses `intl` with the user's locale; the EGX
  ledger however **always** displays EGP as the default currency, with
  conversion in the Inspector.

---

## 9. Iconography

* Base set: **Phosphor** (regular weight, 24 dp). OFL.
* Custom additions:
  * `kero_coptic_cross` — a Coptic cross used for the Spiritual pillar
    tab and the Mass badge.
  * `kero_decision_shield` — used only by the Omniscient Layer.
* All icons ship as `IconData` (via `flutter_icons` codegen) so they
  remain recolourable.

---

## 10. Sound (optional, opt-in)

A small palette of UI sounds, generated on-device via `flutter_soloud`:

| Sound            | Trigger                                  | Duration |
| ---------------- | ---------------------------------------- | -------- |
| `tap_soft`       | Button press                             | 60 ms    |
| `tap_metal`      | Primary CTA                              | 90 ms    |
| `sheet_open`     | Bottom sheet rise                        | 180 ms   |
| `streak_kept`    | Daily completion                         | 240 ms   |
| `wake_ping`      | Wake word recognised                     | 120 ms   |
| `chime_end`      | Decision Break countdown reaches zero    | 320 ms   |

Sounds are **off by default**. The user enables them in
`Settings > Feedback > Sounds`. No sound is ever played before
authentication (i.e. on the lock screen).

---

## 11. Theming API

```dart
final theme = KeroThemeData(
  brightness: Brightness.dark,
  accent: KeroAccent.gold,
  density: KeroDensity.standard,
  motion: KeroMotionScope.system,
);
```

`KeroAccent.gold` is the default. The other options are `KeroAccent.cobalt`
(deep blue, medical-instrument feel) and `KeroAccent.obsidian`
(monochrome with a single warm red accent). Switching accent re-tints the
`accent.kero` token and the chart `data.series.*` palette is rotated to
keep contrast.

`KeroDensity.compact` tightens the spacing scale by 25 % and is intended
for power users on Windows.

---

## 12. Design QA Checklist (per PR)

A PR that touches `kero_design`, any screen, or the theme is **blocked**
until all of the following are true:

- [ ] Visual diff reviewed by the principal engineer on both themes.
- [ ] RTL pass: every screen captured in `ar` locale.
- [ ] Contrast audit with the `colorblind` and `a11y` packages.
- [ ] Dynamic type pass at 0.85 ×, 1.0 ×, 1.4 ×.
- [ ] Reduced-motion pass: animation timeline removed or replaced.
- [ ] Screen-reader pass: VoiceOver (macOS) and TalkBack (Android).
- [ ] Hit-area audit: all interactive elements ≥ 48 × 48 dp on touch.
- [ ] Tab order audit on Windows with keyboard only.

---

*End of design.md. See `agents.md` for the BLoC and repository contracts.*
