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
**Purpose:** To give you radical self-awareness about how you actually spend your digital time, and enforce the behavioral guardrails you set for yourself.

- **Mindless Scrolling Blocker:** System overlay that intercepts blacklisted app launches and enforces a configurable Decision Break timer before granting access.
- **System-Wide Click Logger:** Background accessibility service that parses UI interactions across all running apps, logging what you click, tap, and type (locally).
- **Screen & Unlock Logger:** Precise event timestamps for every screen wake, sleep, and device unlock.
- **Always-Listening Wake-Word Engine ("Ears"):** Fully offline, energy-efficient voice activation using an on-device neural wake-word model. No audio ever leaves the device.

**Why it matters:** Most screen-time apps show you stats passively. ALEF actively intervenes.

---

### Domain 2 — Productivity & Unified Calendar Engine
**Purpose:** A single source of truth for your task list, notes, and schedule — merging your on-device Samsung Calendar and Google Calendar without cloud middlemen.

- **Notes & To-Do Engine:** Hierarchical tasks with parent-child dependency chains, multi-priority queues, and daily checklist pipelines with carry-forward logic.
- **Dual-Calendar Sync:** Direct read/write access to the local Samsung Calendar ContentProvider (via platform channel), plus private Google Calendar OAuth2 integration. All sync logic runs on-device.

---

### Domain 3 — Health, Biometrics & Calorie Intelligence
**Purpose:** A closed-loop health intelligence system that ingests wearable data and correlates it with your dietary intake — entirely offline.

- **Wearable Integration (Honor Watch):** Background polling of Android Health Connect for step counts, heart rate trends, and sleep stage data.
- **Precise Calorie Engine:** A local SQLite-backed ingredient database with per-gram caloric/macro density. No barcode scanning cloud APIs. No external lookups. You weigh ingredients; ALEF computes the rest.

---

### Domain 4 — Wealth & Advanced Financial Ledger
**Purpose:** Professional-grade financial tracking for a freelance income stream and an active EGX investment portfolio, without uploading your net worth to a startup.

- **Freelance Accounting Core:** Multi-currency double-entry bookkeeping. Tracks client invoices, payment receipts, outstanding balances, and currency conversion at snapshot exchange rates (manually updated or scraped locally).
- **Private EGX Portfolio Tracker:** Scrapes publicly available EGX market data locally (or via home server proxy) to compute real-time portfolio valuations, capital gains/losses, and dividend yield tracking.

---

### Domain 5 — Spiritual & Church Life Discipline
**Purpose:** A structured space for spiritual discipline, ministry accountability, and community service management — treated with the highest confidentiality tier in the system.

- **Confessions Log:** Mandatory AES-256 encryption at rest. The user's master passphrase (never stored) derives the encryption key via Argon2. No plaintext ever written to disk.
- **Ministry & Service Management:** A lightweight project management layer for church service tasks, member records, and lesson plan tracking.
- **Holy Mass Attendance:** A streak-based habit tracker with visual consistency grids, longest-streak analytics, and weekly/monthly attendance heatmaps.

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