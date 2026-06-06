# context.md — Product Vision & Privacy Philosophy

## 1. Why This System Exists

Modern personal productivity, health, and financial tools are fundamentally broken from a privacy standpoint. Every calendar sync, every health metric, every financial transaction, and every behavioral pattern you generate is harvested, sold, and monetized by third-party cloud platforms. You are not the customer — you are the product.

**ALEF** (Adaptive Lifelong Ecosystem Framework) was designed around a single non-negotiable axiom:

> *Your data is yours. It lives on your hardware. It leaves only when you explicitly command it.*

ALEF is a unified personal intelligence system that replaces a fragmented ecosystem of SaaS apps (Notion, MyFitnessPal, Google Calendar, personal finance apps, habit trackers) with a single, self-hosted, zero-cloud alternative. The system runs natively on Android and Windows from a single Flutter codebase, with all persistence managed by a private Docker backend and a local Isar cache.

---

## 2. The Zero-Cloud Privacy Philosophy

### Threat Model
ALEF assumes:
- **Cloud providers are adversaries** for the purpose of personal data protection.
- **Network transmission = exposure risk** unless encrypted end-to-end with keys you control.
- **App permissions are attack surfaces** — every sensor, every API, every background service must justify its existence.

### Design Consequences
| Principle | Implementation Outcome |
|---|---|
| No external API calls for core data | Calorie DB, EGX scraper, wake-word model run entirely locally |
| Private OAuth client for Google Calendar | No third-party SDK phoning home; raw OAuth2 PKCE flow only |
| AES-256 client-side encryption | Confessions module data is encrypted *before* it touches Isar or Docker |
| Self-hosted Docker backend | PostgreSQL + Redis + API server live on your own hardware (home server or local NAS) |
| Offline-first architecture | The app operates fully without network; sync is opportunistic, not required |

---

## 3. Feature Domain Map

### Domain 1 — The Omniscient Layer (OS Telemetry & Behavioral Control)
**Purpose:** Give radical self-awareness of digital time use and enforce behavioral boundaries. Optimized for ADHD brains needing active, low-friction control.

- **Omniscient Control Center:** Core configuration interface in settings. Allows toggling background agents (AccessibilityAgent, UsageGuardAgent, ScreenEventAgent, WakeWordAgent), managing app blacklists, defining allowed hours, and setting blocker strictness (Soft countdown vs. Hard Lockout).
- **Mindless Scrolling Blocker:** System overlay intercepting blacklisted app launches, enforcing dynamic Decision Break timers, and offering custom ADHD cognitive reset tasks.
- **System-Wide Click Logger:** Background accessibility service logging tap and click telemetry locally with built-in PII redaction.
- **Screen & Unlock Logger:** Monitors device usage cycles (wake, sleep, unlock frequency).
- **Always-Listening Wake-Word Engine ("Ears"):** Local, offline neural wake-word activation ("Hey Alef") for hands-free tech operations.

---

### Domain 2 — Productivity & Unified Calendar Engine
**Purpose:** Single source of truth for schedule, notes, and tasks, combining local calendar database with Google Calendar OAuth2, optimized for ADHD task-management and college academic cycles.

- **Notes & To-Do Engine:** Hierarchical tasks with parent-child chains, carry-forward checklists, and ADHD focus modes (gamified milestones, pomodoro, micro-task break-downs).
- **Dual-Calendar Sync:** Direct local Samsung Calendar provider reads + private Google Calendar OAuth PKCE.
- **Dynamic Coptic Orthodox Fasting Calendar:** Automatically computes yearly changing Coptic fasting cycles (Great Lent, Apostles' Fast, Jonah's Fast, Advent, Wednesday/Friday fasts) using the Alexandrian Computus algorithm. Displays fasting periods and specific dietary constraints directly in the calendar schedule.

---

### Domain 3 — Health, Biometrics & Calorie Intelligence
**Purpose:** Closed-loop, offline health intelligence system matching active lifestyles and strict dietary disciplines.

- **Wearable Integration (Honor Watch):** Syncs step counts, active heart rate, and sleep quality indexes via Android Health Connect.
- **Egyptian Food Calorie Engine:** Local DB pre-loaded with Egyptian foods (e.g., Ful Medames, Falafel/Ta'ameya, Koshary, Feteer, Egyptian bread) with macro profiles.
- **Orthodox Fasting Toggle:** A single-tap macro toggle that flags non-vegan ingredients (meat, dairy, eggs, fish) and adjusts macronutrient ratios (higher complex carbs, lower animal fats) to support Coptic fasting disciplines automatically.

---

### Domain 4 — Wealth & Advanced Financial Ledger
**Purpose:** Bookkeeping and investment tracker aligned with the user's Management Information Systems (MIS) curriculum, freelance development projects, and prospective banking/fintech career paths.

- **MIS Double-Entry Bookkeeping:** A clean double-entry accounting engine designed around MIS standards. Tracks multi-currency cash flows, client invoice generation (EGP, USD), paid vs. outstanding ledger accounts, and freelancing profits.
- **Egyptian Exchange (EGX) Tracker:** Offline-friendly local web scraper parsing EGX market listings to monitor portfolio valuation, capital gains, and dividend payouts in EGP.
- **Career Preparation Kanban:** Dedicated board tracking banking job applications, software developer certifications, and freelance client pipelines.

---

### Domain 5 — Spiritual & Church Life Discipline
**Purpose:** A secure, high-confidentiality space for Coptic Orthodox spiritual development, service tracking, and liturgy attendance.

- **Confessions Log:** Argon2-derived key with AES-256 client-side encryption. Completely local, excluded from sync outbox. Auto-locks on inactivity.
- **Coptic Ministry & Service Management:** Task coordinator for church classes, member rolls, service duties, and lesson drafting.
- **Holy Liturgy Attendance:** Visual contribution grid (52 weeks x 7 days in deep violet hues) with streak metrics and attendance logging.

---

## 4. Operational Behavior Summary

```
┌─────────────────────────────────────────────────────┐
│                    ALEF ECOSYSTEM                   │
│                                                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────┐  │
│  │ Flutter  │  │  Isar    │  │  Docker Backend  │  │
│  │   App    │◄─│  Cache   │◄─│  (Home Server)   │  │
│  │(Android/ │  │(Offline- │  │  PostgreSQL      │  │
│  │ Windows) │  │  First)  │  │  Redis           │  │
│  └────┬─────┘  └──────────┘  └──────────────────┘  │
│       │                                             │
│  ┌────▼─────────────────────────────────────────┐  │
│  │          Background Agent Layer               │  │
│  │  AccessibilitySvc │ HealthConnect │ WakeWord  │  │
│  │  UsageStats       │ CalendarCP    │ Overlay   │  │
│  └──────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────┘
```

All data flows inward. Nothing exits to third-party infrastructure unless the user initiates an explicit export.