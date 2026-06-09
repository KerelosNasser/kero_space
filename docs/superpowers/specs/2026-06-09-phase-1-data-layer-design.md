# Phase 1: Isar Schema & Core Data Layer Design

## Overview
Phase 1 establishes the foundational data layer for Kero Space using Isar v3. Since Kero Space runs on both **Android** and **Windows**, the data architecture is explicitly designed for seamless multi-device synchronization and device-specific telemetry tracking.

## 1. Database Architecture & Encryption
- **Local Engine:** Isar v3 (unencrypted at rest due to v3 limitations).
- **Application-Level Security:** Highly sensitive fields (e.g., `ConfessionEntry` in the Church module) are encrypted in memory using AES-256-GCM before being stored as raw byte arrays in Isar.
- **Service Locator:** A singleton `IsarService` manages the database lifecycle.

## 2. Multi-Device Synchronization (Android ↔ Windows)
Strong integration between Android and Windows is a core requirement. 
- **Device Attribution:** Every relevant data model (e.g., `TelemetryEvent`, `ScreenEvent`, `Task`) will include a `deviceId` and `platform` field to differentiate Android phone telemetry from Windows desktop telemetry.
- **Offline-First Sync:** Any write operation updates the local Isar collection and simultaneously creates a `SyncOutboxRecord`.
- **Background Sync Worker:** A Dart `SyncWorker` isolate runs every 30 seconds using `Isolate.run()`. It polls the `SyncOutboxRepository`, POSTs new data to the central Docker backend, and fetches remote changes to ensure both devices stay in lockstep.

## 3. Schema Collections
The following schemas are generated via `build_runner`:
- **Telemetry:** `AppUsageRecord`, `ScreenEvent`
- **Productivity:** `Task`, `Note`, `CalendarEvent`
- **Health:** `HealthRecord`, `MealEntry`, `Ingredient`
- **Finance:** `Invoice`, `Transaction`, `EGXHolding`, `EGXPriceSnapshot`
- **Church:** `MassAttendance`, `ConfessionEntry` (encrypted payload), `MinistryTask`
- **System:** `SyncOutboxRecord`

## 4. Data Generation Script (Nutrition)
- A local Python script (`scripts/generate_ingredients.py`) queries the USDA FoodData Central API (for staples) and Open Food Facts (for Egyptian local products).
- The script outputs a heavily curated `assets/ingredients_seed.json` file.
- The `IngredientSeeder` runs on app startup to bulk-insert this data if the collection is empty.
