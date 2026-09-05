# context.md — Product Vision, Privacy Philosophy & Domain Map

## 1. Why This System Exists

Modern personal productivity, health, and financial tools are fundamentally broken from a privacy standpoint. Every calendar sync, health metric, financial transaction, and behavioral pattern you generate is harvested, analyzed, and monetized by cloud platforms. You are not the customer — you are the product.

**Trobio** (formerly *Kero Space*) was designed around a single non-negotiable axiom:

> *Your data is yours. It lives on your hardware. It leaves only when you explicitly command it.*

Trobio is a unified personal intelligence and behavioral OS that replaces fragmented SaaS subscriptions (Notion, MyFitnessPal, Google Calendar, Habitica, Mint, Todoist) with a single, self-hosted, encrypted hub running natively on Android and Windows from a single Flutter codebase. Local persistence is powered by an ACID-compliant Isar cache, synchronized opportunistically to a private self-hosted Docker backend.

---

## 2. The Zero-Cloud Privacy Philosophy

### Threat Model
Trobio assumes:
- **Commercial cloud platforms are adversaries** for the purpose of personal telemetry and behavioral data protection.
- **Network transmission = surface exposure** unless encrypted end-to-end with user-controlled keys.
- **App permissions are attack vectors** — background services, accessibility daemons, and sensors must run locally with strict PII scrubbing.

### Design Consequences
| Principle | Implementation Outcome |
|---|---|
| Zero external API calls for core features | Local Isar database, local Coptic calendar computus, offline wake-word model |
| Private OAuth2 PKCE | Direct Google Calendar sync without intermediary proxy servers |
| AES-256 Client-Side Encryption | Sensitive spiritual/confession records are encrypted before touching storage |
| Automated PII Scrubbing | Accessibility telemetry scrubs passwords, emails, PINs, and credit card numbers at capture time |
| Self-hosted Docker backend | Private PostgreSQL + Redis + Shelf server on home network (LAN / Tailscale) |
| Offline-first architecture | All reads, writes, and analytics execute locally; sync is opportunistic |

---

## 3. Feature Domain Map

### Domain 1 — The Omniscient Layer (OS Telemetry & ADHD Behavioral Control)
**Purpose:** Radical digital self-awareness and hard behavioral boundaries for ADHD focus regulation.
- **Omniscient Control Center**: Master toggles for background daemons (`AccessibilityAgent`, `UsageGuardAgent`, `ScreenEventAgent`, `WakeWordAgent`), app blacklists, and blocker strictness levels.
- **Mindless Scrolling Blocker (`OverlayManager` & `CounterOverlayManager`)**: System-level window overlay intercepting blacklisted apps, enforcing mandatory Decision Break countdowns and bypass friction.
- **Sub-App Detector (`SubAppDetector.kt`)**: Distinguishes productive app sub-features from addictive reels/shorts feeds.
- **System-Wide Click & Input Logger**: Accessibility service capturing UI click streams with automatic client-side PII redaction.
- **Screen & Unlock Dynamics**: Logs wake/sleep cycles, unlock frequencies, and app session durations.
- **Headless BG Isolate**: Android platform events write directly to Isar via a dedicated background Flutter engine (`kero_space/bg/*` channels).
- **Always-Listening Wake-Word ("Hey Kero" / "Trobio")**: On-device micro-acoustic model for voice command capture and hands-free logging.

---

### Domain 2 — Productivity, Deep Work & Unified Calendar
**Purpose:** Single source of truth for scheduling, hierarchical tasks, and notes, optimized for ADHD neurodivergence and university/freelance cycles.
- **Notes & Task Engine**: Parent-child task hierarchies, carry-forward daily checklists, and rich Delta note editing.
- **Deep Work Focus Hub**: Pomodoro session timer widget with haptic phase transitions and ambient focus metrics.
- **Dual-Calendar Sync**: Local device calendar synchronization combined with Google Calendar OAuth2 PKCE.
- **Dynamic Coptic Orthodox Fasting Calendar**: Automatic Alexandrian Computus algorithm computing moveable fasting periods (Great Lent, Apostles' Fast, Jonah's Fast, Advent, Wednesday/Friday fasts) with dietary constraints.

---

### Domain 3 — Health, Nutrition & Workout Intelligence
**Purpose:** Closed-loop, offline health system for physical conditioning, macro tracking, and fasting disciplines.
- **Workout Splits Engine (`lib/features/exercises`)**: Full workout management system with configurable splits (Push/Pull/Legs, Upper/Lower, Bro Split), exercise catalogs, and set/rep/weight logging.
- **Egyptian Food Calorie Database**: Offline database tailored to local Egyptian staples (Ful Medames, Falafel, Koshary, Feteer, Egyptian bread) with full macro profiles.
- **Barcode Scanner**: Instant food identification via OpenFoodFacts (`mobile_scanner`).
- **AI Food Vision Scanner**: Camera snapshot food recognition powered by OpenRouter vision model.
- **Coptic Fasting Macro Switch**: One-tap toggle filtering out non-vegan ingredients (dairy, meat, poultry, fish) and rebalancing macronutrient targets automatically.
- **Health Connect Integration**: Reads step counts, active heart rate, and sleep quality indices via Android Health Connect.

---

### Domain 4 — Wealth, Financial Ledger & EGX Analytics
**Purpose:** Double-entry bookkeeping and investment intelligence aligned with Management Information Systems (MIS) standards and Egyptian financial markets.
- **MIS Double-Entry Accounting**: Income, expense, and multi-currency tracking (EGP, USD) with categorized balance allocations.
- **Bank SMS & Notification Parser (`NotificationParserService`)**: Background parser listening to financial institution SMS/notifications to auto-draft transaction records.
- **Egyptian Exchange (EGX) Tracker**: Offline-friendly scraper tracking stock portfolio holdings, average buy costs, live market values, and watchlists.
- **Budgets & Recurring Subscriptions**: Monthly budget limits by category with renewal interval monitors.

---

### Domain 5 — Spiritual Life & Coptic Church Discipline
**Purpose:** Secure, high-confidentiality sanctuary for Coptic Orthodox spiritual development, service tracking, and liturgy attendance.
- **Encrypted Confessions Sanctuary**: Salted Argon2 key derivation with client-side AES-256-GCM encryption. Local-only; permanently excluded from sync outbox with automatic inactivity lock.
- **Holy Liturgy Attendance**: 52-week contribution heat grid tracking weekly liturgical participation with streak metrics.
- **Dynamic Coptic Tab (`coptic_tab.dart`)**: Daily Coptic calendar date, active fasting seasons, saint feasts of the day, and daily scripture readings integrated via YouVersion API.
- **Ministry & Sunday School Management**: Member directories, lesson notes, and attendance rolls for church services.

---

### Domain 6 — Interface & Navigation Systems
**Purpose:** Highly customizable, aesthetic UI engineered for developer ergonomics and cognitive efficiency.
- **11 Curated Theme Presets**:
  - *Monochrome Industrial* (Braun / Dieter Rams functionalism)
  - *Gruvbox Tactical* (Warm Unix hacker aesthetic)
  - *Amber CRT Console* (VT220 phosphor amber)
  - *Nordic Slate* (Arctic IDE clarity)
  - *Mil-Spec HUD* (Tactical radar interface)
  - *Graphite Monolith* (Swiss aerospace geometry)
  - *Solarized Core* (Scientific lab workstation)
  - *Tokyo Midnight* (Stealth cyberpunk terminal)
  - *Drafting Blueprint* (CAD architectural schematics)
  - *Catppuccin Studio* (Low-strain matte pastel focus)
  - *Custom Developer Theme* (Real-time tweaking via `CustomThemeStudioScreen`)
- **5 Navigation Paradigms**:
  1. *Command Capsule* (3-slot dock with center ⌘ Raycast-style command palette modal)
  2. *Three-Pillar Triad* (Hierarchical Home, Life OS, System & Spirit grouping)
  3. *Floating Island Dock* (Minimalist floating pill)
  4. *Bento Control Hub* (Glanceable 2x3 control tile launcher)
  5. *Classic 6-Tab Bar* (Traditional horizontal tab bar)
- **Command Palette (`CommandRegistry.dart`)**: Quick fuzzy navigation, quick note capture, timer shortcuts, and intent execution.

---

## 4. Operational Topology

```
┌────────────────────────────────────────────────────────────────────────┐
│                        TROBIO SYSTEM ARCHITECTURE                      │
│                                                                        │
│  ┌─────────────────────────┐              ┌─────────────────────────┐  │
│  │      Flutter App        │              │  Android Native Daemons │  │
│  │   (Android & Windows)   │              │   • AccessibilitySvc    │  │
│  │   • UI State Machines   │◄────────────►│   • ForegroundService   │  │
│  │   • BLoC / Cubit Layer  │ EventChannel │   • CounterOverlay      │  │
│  │   • Theme & Nav Engine  │ MethodChannel│   • WakeWordService     │  │
│  └────────────┬────────────┘              └────────────┬────────────┘  │
│               │                                        │               │
│               ▼                                        ▼               │
│  ┌─────────────────────────┐              ┌─────────────────────────┐  │
│  │    Local Isar Cache     │◄─────────────┤  Headless BG Isolate    │  │
│  │  (Zero-Cloud Persistence│              │ (kero_space/bg/* stream)│  │
│  └────────────┬────────────┘              └─────────────────────────┘  │
│               │                                                        │
│               ▼ (Encrypted Opportunistic Sync)                         │
│  ┌─────────────────────────┐                                           │
│  │   Docker Home Server    │                                           │
│  │  • Shelf REST Server    │                                           │
│  │  • PostgreSQL + Redis   │                                           │
│  └─────────────────────────┘                                           │
└────────────────────────────────────────────────────────────────────────┘
```

All data flows inward. Storage defaults to local hardware. External network calls only occur for explicitly user-configured features (AI food vision or YouVersion scripture).