# Exercises Tab — Health Module

## Overview
Add a top TabBar to the Health screen with two tabs: **Nutrition** (existing content) and **Exercises** (new). The Exercises tab organizes 1,324 exercises from the [exercises-dataset](https://github.com/hasaneyldrm/exercises-dataset) into pre-defined workout splits, auto-schedules today's workout by weekday, and logs sets × reps × weight.

## Data Model — 6 new Isar collections

### Exercise
Seeded from dataset JSON (`assets/exercises_seed.json` — downloaded from the repo).

| Field | Type | Notes |
|-------|------|-------|
| id | int | Isar autoIncrement |
| name | string | e.g., "Barbell Bench Press" |
| category | string | body part: "chest", "back", etc. |
| equipment | string | "barbell", "dumbbell", "body weight", etc. |
| target | string | primary muscle: "pectorals", "lats", etc. |
| muscleGroup | string | synergist muscle group |
| secondaryMuscles | string | comma-separated |
| instructionsEn | string | step-by-step in English |

Other languages from the dataset can be added later. Media (images/GIFs) not included per dataset license.

### WorkoutSplit
| Field | Type | Notes |
|-------|------|-------|
| id | int | Isar autoIncrement |
| name | string | "PPL", "Arnold Split", etc. |
| description | string | short description |
| daysPerWeek | int | 3, 4, 5, or 6 |
| sortOrder | int | display order |

### WorkoutDay
| Field | Type | Notes |
|-------|------|-------|
| id | int | Isar autoIncrement |
| splitId | int | belongs to WorkoutSplit |
| dayName | string | "Push A", "Upper A", etc. |
| dayOfWeekMask | int | bitmask (1=Mon, 2=Tue, 4=Wed, 8=Thu, 16=Fri, 32=Sat, 64=Sun) |
| sortOrder | int | within split |

### WorkoutDayExercise
Pre-assigned exercises for each day in each split.

| Field | Type | Notes |
|-------|------|-------|
| id | int | Isar autoIncrement |
| dayId | int | belongs to WorkoutDay |
| exerciseId | int | references Exercise |
| sets | int | default set count (e.g., 4) |
| targetReps | string | e.g., "8-12" |
| sortOrder | int | exercise order within day |

### WorkoutLog
One log per workout session.

| Field | Type | Notes |
|-------|------|-------|
| id | int | Isar autoIncrement |
| splitId | int | which split was used |
| dayId | int | which day was performed |
| date | DateTime | workout date |
| notes | string? | optional user notes |

### WorkoutSet
Individual set within a logged exercise.

| Field | Type | Notes |
|-------|------|-------|
| id | int | Isar autoIncrement |
| logId | int | belongs to WorkoutLog |
| dayExerciseId | int | which exercise in the day |
| setNumber | int | 1, 2, 3, ... |
| reps | int | reps performed |
| weight | double | weight in kg |

## Pre-loaded Splits (6)

| Split | Days | Structure |
|-------|------|-----------|
| **Full Body** | 3 | Full A, Full B, Full C |
| **Upper/Lower** | 4 | Upper A, Lower A, Upper B, Lower B |
| **Bro Split** | 5 | Chest, Back, Shoulders, Legs, Arms |
| **PPLUL** | 5 | Push, Pull, Legs, Upper, Lower |
| **PPL** | 6 | Push A, Pull A, Legs A, Push B, Pull B, Legs B |
| **Arnold Split** | 6 | Chest+Back, Shoulders+Arms, Legs (x2) |

Each day's exercises are pre-assigned from the dataset filtered by target muscle group. ~6-8 exercises per day.

## Auto-Schedule Logic

```
getTodayWorkout(userSplit, today):
  todayMask = 1 << (weekday - 1)  // Mon=1, Tue=2, ...
  return first WorkoutDay in userSplit where
    dayOfWeekMask & todayMask != 0
    and sortOrder cycles through rotation
```

Rotation: track which "week" of the rotation the user is on. E.g., PPL 6-day: if today is Monday and the last logged workout was Push A, the next Monday should show Push B (alternating).

## UI Structure

```
HealthScreen (add TabBar)
├── Nutrition tab (existing — unchanged)
└── Exercises tab
     ├── Split selector — horizontal chip bar at top
     │    Shows active split name, tap to change
     ├── Today's workout card
     │    ├── Header: "Monday • Push A"
     │    ├── Date badge
     │    └── List of exercise cards:
     │         ├── Exercise name + target muscle + equipment
     │         ├── Set rows: [Set 1: 40kg x 10 ✔] [Set 2: 40kg x 8] [+]
     │         └── Tap set to edit reps/weight
     └── History section (collapsible)
          └── Last 7 workout logs with summary
```

## BLoC

### ExerciseBloc
- **Events**: SelectSplit, LoadTodayWorkout, LogSet, CompleteWorkout, LoadHistory
- **State**: selectedSplit, todayExercises, workoutLogs, isCheckedIn (started today's workout)

## Data Flow

```
1. App start → seed Exercise from JSON if not seeded
2. Pre-load WorkoutSplit + WorkoutDay + WorkoutDayExercise from seed JSON
3. ExerciseBloc.loadTodayWorkout → query WorkoutDay by split + dayOfWeekMask
4. User logs sets → WorkoutSet written to Isar
5. On complete → WorkoutLog written with all sets
```

## Seed Data
- `assets/exercises_seed.json` — all 1,324 exercises from the dataset
- `assets/splits_seed.json` — all 6 splits, their days, and pre-assigned exercise IDs + set/defaults

## Future (v2)
- Progress charts (weight lifted over time per exercise)
- Exercise swap / custom exercises
- Rest timer
- Warm-up sets
- RIR/RPE logging

## Open Questions
- Exercise media — the dataset doesn't include images/GIFs. Show icon/placeholder for now.
- Equipment filter — user may not have access to all gym equipment. Add later.
