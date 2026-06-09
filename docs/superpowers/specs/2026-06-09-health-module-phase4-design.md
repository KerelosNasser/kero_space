# Phase 4 — Health Module Design Spec

## Overview
Phase 4 introduces the Health Module to Kero Space. It focuses on two main pillars:
1. **Biometrics Tracking**: Reading steps, heart rate, and sleep data from Android Health Connect.
2. **Nutrition & Calorie Engine**: Tracking meals, daily caloric/macro limits, and incorporating Coptic Orthodox Fasting logic.

## Architecture

### Data Sources
- **Health Connect API**: Fetches read-only biometric data. Triggered periodically via an Android WorkManager.
- **Isar Database**: 
  - `HealthRecord`: Persists biometric snapshots locally.
  - `MealEntry`: Logs consumed meals with computed macros.
  - `Ingredient`: Stores known foods. Can be seeded and user-extended.
  - `UserProfile`: Stores physical attributes (height, weight, age) for BMR tracking.

### Coptic Fasting Logic
- A toggle switch in the UI allows activating "Fasting Mode".
- When active, the system adjusts visual macro target ratios (e.g., favoring plant-based proteins/carbs) and presents a **Soft Warning** (Dialog/Toast) if the user attempts to log an ingredient where `isFastingCompliant == false`.

### Extensible Ingredient DB
- The app will seed from `assets/ingredients_seed.json` initially.
- If an ingredient is missing, users can manually create a custom `Ingredient` record, which saves to Isar and becomes immediately searchable.

## Visuals & Components
- **Health Dashboard**: Aggregated views using `fl_chart`. Features ring indicators for daily calorie goals against BMR.
- **Meal Log Flow**: Debounced search -> Select Ingredient -> Enter Grams -> Preview Macros -> Confirm (with Fasting check) -> Save.

## Implementation Plan
See the accompanying `implementation_plan.md` artifact for exact file targets and code changes.
