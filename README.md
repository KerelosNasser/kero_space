# Trobio (Kero Space)

> **Zero-Cloud Personal Intelligence & Behavioral Control OS**  
> Built with Flutter (Android & Windows), Isar Database, and Kotlin Background Daemon Services.

---

## 1. Overview

**Trobio** (formerly *Kero Space*) is a privacy-first, offline-first personal operating system designed to replace fragmented SaaS subscriptions (Notion, MyFitnessPal, Google Calendar, Habitica, Mint) with a unified, self-hosted, encrypted hub running on your own hardware.

It is tailored for high-cognition workflows, ADHD behavioral management, Egyptian Coptic Orthodox disciplines, and financial/career tracking.

```
┌────────────────────────────────────────────────────────────────────────┐
│                         TROBIO SYSTEM TOPOLOGY                         │
│                                                                        │
│  ┌─────────────────────────┐              ┌─────────────────────────┐  │
│  │   Flutter UI Layer      │              │  Android Native Daemons │  │
│  │   • 5 Navigation Modes  │◄────────────►│  • AccessibilityService │  │
│  │   • 11 Theme Presets    │ Method/Event │  • ForegroundService    │  │
│  │   • Raycast Palette ⌘   │   Channels   │  • CounterOverlayManager│  │
│  │   • 10 Feature Domains  │              │  • WakeWordService      │  │
│  └────────────┬────────────┘              └────────────┬────────────┘  │
│               │                                        │               │
│               ▼                                        ▼               │
│  ┌─────────────────────────┐              ┌─────────────────────────┐  │
│  │   Local Isar Cache      │◄─────────────┤  Headless BG Isolate    │  │
│  │   (Encrypted / Fast)    │              │  (Writes telemetry dir) │  │
│  └────────────┬────────────┘              └─────────────────────────┘  │
│               │                                                        │
│               ▼ (Opportunistic Sync)                                   │
│  ┌─────────────────────────┐                                           │
│  │  Self-Hosted Docker Svc │                                           │
│  │  (PostgreSQL + Redis)   │                                           │
│  └─────────────────────────┘                                           │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Key Modules & Capabilities

### 🧠 Omniscient Layer (Behavioral Telemetry & ADHD Control)
- **Mindless Scrolling Blocker**: `CounterOverlayManager` and `OverlayManager` intercept blacklisted app launches, enforcing customizable Decision Break countdowns and bypass friction.
- **System-Wide Telemetry**: Background accessibility service monitors click streams with automated local PII sanitization (passwords, emails, card numbers).
- **Screen & Unlock Dynamics**: Tracks unlock frequencies, screen-on durations, and awake/sleep cycles.
- **Headless BG Isolate**: Android events pipe to a background Flutter isolate (`backgroundMain`) writing directly to Isar via `kero_space/bg/*` channels.

### 🎙️ Hands-Free Voice Assistant ("Hey Kero" / "Trobio")
- Offline wake-word detection using native micro-acoustic model.
- Fast command parser supporting task additions, note creation, meal logging, expense capture, liturgical attendance marking, and app blocking.
- Confirmation modal with speech transcription telemetry.

### ⚡ Productivity & Unified Calendar
- Hierarchical task trees, carry-forward daily checklists, and note editor with rich Delta formatting.
- Deep work Pomodoro timer widget with audio/haptic checkpoints.
- Dual-calendar integration: Local calendar provider sync + Coptic Orthodox Alexandrian Computus cycle computation.

### 🥗 Health, Nutrition & Workout Intelligence
- **Egypt-Centric Calorie Engine**: Local food database tailored to Egyptian cuisine (Ful, Koshary, Falafel, etc.) with macro breakdowns.
- **Barcode Scanner**: OpenFoodFacts scanner via `mobile_scanner`.
- **AI Food Vision Scanner**: Camera snapshot food recognition via OpenRouter vision model.
- **Coptic Fasting Toggle**: Auto-filters vegan food rules (dairy, meat, poultry, fish constraints).
- **Exercises Subsystem**: Multi-split workout manager (PPL, Upper/Lower, Bro Split), exercise logging, and history tracking.

### 💰 Wealth & Financial Ledger
- Double-entry accounting system with income, expense, and category tagging.
- Automated banking notification/SMS parser (`NotificationParserService`) for instant transaction logging.
- **EGX Stock Portfolio Tracker**: Egyptian Exchange portfolio tracker with holding valuations and watchlist monitor.
- Subscriptions and monthly recurring budget monitors.

### ⛪ Spiritual Life & Coptic Orthodox Discipline
- **Encrypted Confessions Log**: Argon2 key derivation with client-side AES-256-GCM encryption; isolated from sync outbox.
- **Liturgical Attendance Heatmap**: 52-week contribution grid tracking Sunday/feast liturgies with streak counters.
- **Dynamic Coptic Tab**: Computes daily Coptic dates, fasting status, saint feasts, and fetches daily scripture readings via YouVersion API.
- **Ministry Kanban**: Member directories, lesson drafting, and class attendance registers.

### 🎨 Design & Navigation Engine
- **11 Presets**: Monochrome Industrial, Gruvbox Tactical, Amber CRT, Nordic Slate, Mil-Spec HUD, Graphite Monolith, Solarized Core, Tokyo Midnight, Blueprint, Catppuccin, and Custom.
- **Custom Theme Studio**: Fine-tune contrast, surface elevations, and accent palettes in real-time.
- **5 Navigation Modes**:
  1. *Command Capsule* (Raycast-style ⌘ palette & quick actions)
  2. *Three-Pillar Triad* (Home, Life OS, System & Spirit)
  3. *Floating Island Dock*
  4. *Bento Control Hub*
  5. *Classic 6-Tab Bar*

---

## 3. Technology Stack

- **Framework**: [Flutter 3.x](https://flutter.dev) (Dart 3)
- **Local Persistence**: [Isar Database](https://isar.dev) v3 (ACID, multi-process, zero-copy)
- **State Management**: [flutter_bloc](https://pub.dev/packages/flutter_bloc) + [get_it](https://pub.dev/packages/get_it) dependency injection
- **Routing**: [go_router](https://pub.dev/packages/go_router) with stateful nested shell branches
- **Native Android**: Kotlin, AccessibilityService, Foreground Service, WindowManager Overlays, VoiceInteractionService
- **Backend (Self-Hosted)**: Dart Shelf server / Docker container with PostgreSQL & Redis

---

## 4. Getting Started

### Prerequisites
- Flutter SDK `>=3.3.0`
- Android SDK (API 34+)
- Visual Studio / Desktop C++ toolchain (for Windows builds)

### Configuration
1. Clone the repository and install dependencies:
   ```bash
   flutter pub get
   ```

2. Setup environment variables:
   ```bash
   cp .env.example .env
   ```
   Provide optional keys for extended cloud services:
   ```ini
   OPENROUTER_API_KEY=your_openrouter_key   # For AI Food Vision scanner
   YOUVERSION_API_KEY=your_youversion_key   # For Coptic daily scripture readings
   ```

3. Generate Isar models if modified:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. Run the app:
   ```bash
   # Android target (recommended for full daemon capabilities)
   flutter run -d android

   # Windows target
   flutter run -d windows
   ```

---

## 5. Security & Privacy Model

1. **Zero External Sync by Default**: All data remains in local Isar collections unless explicitly pointed to a private Docker backend.
2. **Client-Side Encryption**: Sensitive confession logs use salted Argon2 hashing with AES-256-GCM encryption and auto-lock timeouts.
3. **PII Redaction**: Background accessibility logger redacts passwords, pins, emails, and card numbers before events touch Isar or memory buffers.
