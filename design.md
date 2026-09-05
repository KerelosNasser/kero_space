# design.md — UI/UX Philosophy, Theming Engine & Navigation Systems

## 1. Design Philosophy: Industrial Functionalism & Spatial Focus

Trobio's visual system balances high information density with zero cognitive clutter. It is built for developers, neurodivergent minds (ADHD), and disciplined practitioners who demand high-contrast legibility, tactile feedback, and modular workflows.

Rather than locking the user into a single aesthetic, Trobio provides an **11-theme engine** ranging from Dieter Rams-inspired minimalism to retro Unix terminals and cyberpunk HUDs, paired with **5 distinct navigation paradigms**.

---

## 2. Dynamic Theming Engine (`AppTheme`)

The theming system lives in `lib/core/app_theme.dart` and is powered by Flutter's `ThemeExtension` (`AppColorsExtension`), accessible anywhere via `context.appColors`.

### Curated Theme Presets

| Theme ID | Preset Name | Tag | Aesthetic Description |
|---|---|---|---|
| `monochrome` | **Monochrome Industrial** | `INDUSTRIAL` | Braun & Dieter Rams functionalism. Pure signal, stark high-contrast black & white. |
| `gruvbox` | **Gruvbox Tactical** | `RETRO UNIX` | Warm Unix hacker terminal. Earthy tones designed for zero eye fatigue during late nights. |
| `amberCrt` | **Amber CRT Console** | `TERMINAL` | VT220 phosphor amber on pitch black. Vintage mainframe feel. |
| `nordic` | **Nordic Slate** | `ARCTIC` | Arctic IDE precision. Cold slate surfaces with balanced syntax clarity. |
| `milSpecHud` | **Mil-Spec HUD** | `MIL-SPEC` | Tactical telemetry radar. High-contrast terminal greens with diagnostic unit borders. |
| `graphite` | **Graphite Monolith** | `SWISS` | Swiss aerospace geometry. Subtle charcoal elevations with disciplined typography. |
| `solarized` | **Solarized Core** | `SCIENTIFIC` | Mathematically tuned scientific lab workstation with low cognitive strain. |
| `tokyoNight` | **Tokyo Midnight** | `MIDNIGHT` | Stealth modern terminal illuminated with laser cyan and neon violet accents. |
| `draftingBlueprint` | **Drafting Blueprint** | `SCHEMATIC` | Deep blueprint blues with architectural drafting grids and precise technical lines. |
| `catppuccin` | **Catppuccin Studio** | `STUDIO` | Matte low-strain pastel studio palette optimized for deep focus sprints. |
| `custom` | **Custom Developer Theme** | `CUSTOM` | User-tailored palette configured in real-time via `CustomThemeStudioScreen`. |

### Design Tokens (`AppColorsExtension`)

Every theme implements the standardized token interface:

```dart
final colors = context.appColors;

// Backgrounds
colors.bgPrimary    // Base canvas (OLED Black #000000 or deep tinted canvas)
colors.bgSurface    // Card, tile, and sheet background
colors.bgElevated   // Modal dialogs, popup menus, active chips
colors.bgOverlay    // High-blur backdrop filter (glassmorphic overlays)

// Accents
colors.accentPrimary // Primary action emphasis
colors.accentMint    // Success states, calorie rings, positive financial delta
colors.accentRose    // Destruction, warnings, app blocking, error badges
colors.accentGold    // Alerts, high-priority tasks, fasting notices
colors.accentViolet  // Spiritual life, Coptic feast highlights, liturgy
colors.accentCyan    // Telemetry graphs, interactive links, secondary accents

// Typography
colors.textPrimary   // High-contrast primary headers and body text
colors.textSecondary // De-emphasized labels, timestamps, metadata
colors.textDisabled  // Inactive states, placeholder cues

// Structure & Chrome
colors.glassBorder   // Subtle translucent 1px card separators
colors.borderGlow    // Interactive focus rings and highlighted active cards
colors.chartGrid     // Telemetry & finance line chart grid marks
colors.divider       // Section separators
```

### Custom Theme Studio (`CustomThemeStudioScreen`)
Provides an in-app laboratory where users can customize:
- Primary background darkness & surface tinting
- Accent hue shift & saturation
- Glassmorphism blur opacity and border intensity
- Real-time preview against sample cards, charts, and buttons before committing

---

## 3. The 5 Navigation Paradigms (`AppNavStyle`)

Managed dynamically by `NavigationCubit` (`lib/core/navigation/navigation_cubit.dart`) and rendered by `AppShell`:

```
┌────────────────────────────────────────────────────────────────────────┐
│                        NAVIGATION PARADIGMS                            │
│                                                                        │
│  1. Command Capsule       [ Productivity ]   [ ⌘ ]   [ Life OS ]       │
│  2. Three-Pillar Triad    [    Home    ]  [  Life OS  ]  [ System/Sp ] │
│  3. Floating Island Dock  (  • Home   • Health   • Finance   • ...  )  │
│  4. Bento Control Hub     [ 2x3 Glanceable Interactive Module Grid ]   │
│  5. Classic Bar           [ Home | Prod | Health | Fin | Church | Tel ]│
└────────────────────────────────────────────────────────────────────────┘
```

### 1. Command Capsule (Recommended Default)
- Sleek 3-slot bottom bar with a prominent center **⌘ Command Palette button**.
- Flanking slots provide quick jumps between active work domains.
- Tapping ⌘ triggers the Raycast-style `CommandPaletteModal`.

### 2. Three-Pillar Triad
- Groups the 6 operational domains into 3 logical pillars:
  - **Home**: Today's Focus, unified timeline, daily agenda.
  - **Life OS**: Productivity, Health & Workouts, Wealth & Financial Ledger.
  - **System & Spirit**: Church & Coptic Life, Telemetry & Blocker Controls.
- Features intuitive segmented sub-switchers within each pillar.

### 3. Floating Island Dock
- Elevated, floating pill hovering above screen content with subtle drop shadows and glass borders.
- Animates active tabs smoothly with spring physics.

### 4. Bento Control Hub
- Replaces static navigation with a modular 2x3 bento dashboard (`BentoHubSheet`).
- Each bento tile displays live telemetry glanceables (today's screen time, active fasting status, pending tasks) while serving as a direct module launcher.

### 5. Classic 6-Tab Bar
- Direct, horizontal bottom navigation exposing all primary modules simultaneously.

---

## 4. Raycast-Style Command Palette (`CommandRegistry`)

The Command Palette (`lib/shared/widgets/navigation/command_palette_modal.dart`) provides keyboard-first, rapid-fire operational control:
- **Instant Search**: Fuzzy filtering across all modules, sub-screens, and settings.
- **Action Shortcuts**: Quick note creation, fast expense logging, instant deep work timer start.
- **Intent Integration**: Routes parsed intents from voice or text input directly into corresponding BLoC events.
- **AI Quick Answer**: Embedded sheet for immediate offline calculations or assistant queries.

---

## 5. Motion, Haptics & Accessibility

- **Spring Physics**: Navigation transitions and modal presentations use Apple-inspired cubic spring curves (`Curves.easeOutCubic`, `Curves.easeInOutCubic`).
- **Haptic Tactility**: Heavy/medium haptic feedback on blocker countdown bypass, task completion, and deep work timer phase changes.
- **OLED Optimization**: Black-canvas themes (`monochrome`, `amberCrt`, `milSpecHud`) turn off OLED pixels completely to optimize battery life during background monitoring.