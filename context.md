# Pillar — Context

> Vision, mission, principles, scope, and glossary for the **Kero.Space** private
> personal-assistant ecosystem. This file defines *what* we are building and *why*.
> The *how* lives in `architecture.md`, `design.md`, `agents.md`, and `tasks.md`.

---

## 1. Product Name & Identity

| Field        | Value                                                              |
| ------------ | ------------------------------------------------------------------ |
| Working name | `kero_space` (Flutter package) / "Kero" (consumer name)            |
| Domain       | Android (mobile + Wear companion), Windows 10/11 desktop            |
| Codename     | **Pillar**                                                         |
| Document set | `context.md`, `architecture.md`, `design.md`, `agents.md`, `tasks.md` |
| SSOT owner   | Principal Engineer                                                 |
| Version      | 0.1.0 (pre-implementation baseline)                                |

---

## 2. Mission Statement

> Build a **completely private**, **offline-first**, **locally intelligent**
> personal assistant that runs on the user's own hardware, persists every byte
> of state to a self-hosted Docker backend the user controls, and is **never
> required** to round-trip any datum — voice, click, calendar, money, health,
> or faith — to a third-party cloud in order to function.

The product is a **single binary surface** (one Flutter app, one backend
container stack) that replaces the typical constellation of cloud SaaS (Google
Calendar, Notion, MyFitnessPal, YNAB, RescueTime, Stock-market trackers,
Saint-of-the-Day apps, etc.) with a single, encrypted, locally-owned system.

---

## 3. The Six Pillars

The product is organised into six primary feature pillars, each of which is a
self-contained vertical with its own BLoC, repository, Isar collection family,
and Docker micro-service. Pillar boundaries are non-negotiable — a feature
inside one pillar **must not** import from another pillar's domain layer.

| #   | Pillar                  | One-line purpose                                                |
| --- | ----------------------- | --------------------------------------------------------------- |
| 1   | **Omniscient Layer**    | OS-level behavioural telemetry, intervention, and voice        |
| 2   | **Productivity**        | Notes, tasks, dual-calendar sync                                |
| 3   | **Health & Biometrics** | Wearable ingestion, calorie & macro engine                      |
| 4   | **Wealth**              | Double-entry freelance accounting, EGX portfolio                 |
| 5   | **Spiritual**           | Encrypted confessional log, ministry CRM, Mass streaks          |
| 6   | **Analytics**           | Cross-pillar statistical dashboards                             |

Pillar **0** is the **Foundation**: security, sync, schema, observability.
Every pillar depends on Pillar 0 and is independent of all other pillars.

---

## 4. Guiding Principles

These are non-negotiable. Any PR that violates one is rejected at review.

### 4.1 Privacy is structural, not configurable

Data leaves the device **only** when the user explicitly opts in to a specific
sync target. There is no "telemetry" channel. There is no "anonymous usage
stats". There is no "crash reporter" that phones home. Background services
that listen (microphone, accessibility, foreground app) hold their samples in
memory and write **only to the local Isar cache**; they never open a network
socket.

### 4.2 Offline-first

Every feature must function on a plane with no Wi-Fi, no SIM, and no
backend reachable. The Docker backend is a **durability and cross-device
replication** layer, not a runtime dependency. If the backend is down, the
user must not notice a regression in any interactive flow.

### 4.3 Local intelligence, not cloud intelligence

Wake-word detection, calorie calculation, and behavioural classification all
run on-device. The Docker backend may **also** host heavier models (e.g.
embedding generation for the analytics layer) but is never the *only* place
an inference can happen.

### 4.4 The user is the only keyholder

The Confessional, Ministry, and Health pillars carry information whose
disclosure would cause real-world harm. Pillar 5 (Spiritual) and Pillar 3
(Health) are encrypted **client-side** with keys derived from a passphrase
that is never persisted. The Docker backend stores ciphertext only.

### 4.5 Predictable state, observable behaviour

All interactive flows are implemented in BLoC. State is finite, enumerable,
and inspectable. Side-effects (DB writes, network, platform channels) are
funneled through repositories; BLoCs never touch the platform directly.
This makes every flow replayable in widget tests and reproducible in
production logs.

### 4.6 Calming motion, never theatrical

Charts glide, panels fade, modals rise. The interface is a calm companion,
not a slot machine. All motion is interruptible, accessibility-respectful
(`prefers-reduced-motion`), and never blocks a frame for longer than 16 ms
on the target device.

---

## 5. Target User Persona

```
Name:        Karim
Age:         32
Devices:     Honor Magic 6 Pro (Android 14), Honor Watch GS Pro,
             Windows 11 desktop, home server (Ryzen 5, 32 GB RAM)
Profession:  Freelance software consultant, Coptic Orthodox,
             part-time church ministry leader
Daily time:  ~14 h phone, ~9 h desktop, 6 h sleep tracked, 2 h exercise
Pain points:
  - Drowning in SaaS subscriptions and fragmented data
  - Wants to track finances, faith, and focus in ONE private place
  - Egyptian Pound volatility means he needs a real portfolio tracker
  - Has been burned by cloud breaches; refuses to upload Confessional data
Tech literacy: high. Comfortable with Docker, SSH, and reading a JSON log.
```

Karim is the design anchor. Every feature decision is run through
*"would Karim (and only Karim) be comfortable with this on-device?"*. The
app is **not** multi-tenant. It is not a SaaS. It is one person's local
command center, with the engineering rigour of a multi-tenant product.

---

## 6. In-Scope vs Out-of-Scope

### 6.1 In scope (v1.0)

- All six pillars, end to end.
- Single Android user, single Windows user, one Docker backend.
- Two calendar providers: Samsung Calendar (local ContentProvider) and
  Google Calendar (user-owned OAuth client, read-write).
- Health Connect ingestion from Honor Watch via the official `health` package.
- One trading venue: Egyptian Stock Exchange (EGX).
- One faith tradition (designed with the Coptic Orthodox context in mind
  but domain-agnostic; can be re-skinned for any liturgical tradition).
- English and Modern Standard Arabic UI strings.
- Dark and light themes; full WCAG 2.2 AA compliance.

### 6.2 Out of scope (v1.0)

- Multi-user / multi-tenant accounts.
- Cloud-hosted backend (the Docker stack is local-network only).
- iOS, macOS, Linux, web. (Flutter projects for those platforms exist as
  build targets but are not part of the v1.0 release.)
- Cross-device realtime co-editing.
- Voice-to-text transcription (wake-word only; full ASR is a v2 feature).
- Trading execution (read-only EGX data; no broker integration).
- Tax filing, legal accounting, or audited financial statements.
- Sacraments-of-the-Church data modelling beyond attendance and ministry
  task tracking.

### 6.3 Non-Goals (explicitly rejected)

- **Social features.** No friends, no leaderboards, no sharing.
- **Gamification beyond habit streaks.** No XP, no badges.
- **AI-generated content surfaced as "user data".** LLM assists are
  sandboxed inside a "Coach" tool and never get write access to any pillar.
- **Ads, upsells, premium tiers.** The product is a personal tool.

---

## 7. Glossary

| Term                | Definition                                                                                                |
| ------------------- | --------------------------------------------------------------------------------------------------------- |
| **Pillar**          | One of the six top-level feature areas (Omniscient, Productivity, Health, Wealth, Spiritual, Analytics).   |
| **Foundation**      | Pillar 0: cross-cutting concerns (security, sync, schema, observability).                                 |
| **BLoC**            | Business Logic Component — event-in, state-out state machine used for all interactive flows.             |
| **Repository**      | The only layer below a BLoC. Owns the local cache, the sync queue, and (where applicable) the remote API. |
| **Isar**            | Embedded NoSQL object database used as the reactive local cache.                                          |
| **Decision Break**  | A user-mandated delay (e.g. 30 s) that must elapse before a blacklisted app can be used.                  |
| **Coach**           | Optional on-device LLM that can *suggest* but never *write* to user data.                                 |
| **Sync Vector**     | A monotonically increasing per-collection version number used for last-writer-wins conflict resolution.   |
| **Keyring**         | The in-memory store of derived keys, populated on app launch, zeroed on background.                       |
| **Vault**           | A logical grouping of encrypted collections (e.g. `vault.spiritual`, `vault.health`).                     |
| **Telemetry Probe** | A background service that reads OS state (app foreground, screen on/off, accessibility events).          |
| **Wake Word**       | An on-device keyword-spotting model (default: "Hey Kero"). Runs offline.                                  |
| **Dock**            | The user's self-hosted Docker backend (FastAPI + Postgres + Redis + MinIO).                               |
| **EGX**             | Egyptian Stock Exchange. Public market data is fetched via private scripts and cached locally.            |
| **RRR**             | Reduce, Reuse, Recycle — internal code principle: never copy a BLoC, never duplicate a repository.        |

---

## 8. Success Metrics (v1.0)

A successful v1.0 is when the following are demonstrably true:

1. **Zero outbound bytes** to any host that is not the user's Docker backend,
   verified by a packet capture during a 24-hour soak test.
2. **All six pillars** score ≥ 90 % on the in-house feature-completeness
   checklist (see `tasks.md` §10).
3. **Cold-start to interactive** under 1.8 s on a Honor Magic 6 Pro and
   under 2.5 s on a mid-range Windows 11 laptop.
4. **Wake-word end-to-end latency** under 400 ms from utterance to action.
5. **Decision Break** verified to be unbypassable by switching apps,
   rebooting, or killing the foreground service.
6. **Confessional data** cannot be read by anyone with full disk access to
   the Docker backend volume (encryption-at-rest verified by a red-team
   review).
7. **WCAG 2.2 AA** automated audit passes 100 % on the six primary screens.

---

## 9. Stakeholders & Decision Rights

| Role                  | Responsibility                                                | Decision right                                |
| --------------------- | ------------------------------------------------------------- | --------------------------------------------- |
| Principal Engineer    | Architecture, security, release                               | Final say on all technical decisions          |
| Product Owner (Karim) | Priorities, scope, faith-domain correctness                   | Final say on feature scope & non-goals        |
| Reviewers (rotating)  | Code review, accessibility review                             | Block merge on hard-rule violations           |
| Future self (v2.0)    | Inherit a codebase that is a pleasure to extend               | —                                             |

There is no product manager, no scrum master, no standup. There is one
engineer with a checklist and a calendar.

---

## 10. Document Map

```
context.md       You are here. Defines the why and the what.
architecture.md  Defines the how at the system level.
design.md        Defines the how at the user-facing level.
agents.md        Defines the how at the code level (BLoCs, repos, services).
tasks.md         Defines the order in which we build, verify, and ship.
```

If a decision in `agents.md` contradicts `context.md`, **context wins**.
If `design.md` contradicts `architecture.md`, **architecture wins**.
If `tasks.md` contradicts any of the above, **the above wins** — and
`tasks.md` is updated.

---

*End of context.md. See `architecture.md` for the system design.*
