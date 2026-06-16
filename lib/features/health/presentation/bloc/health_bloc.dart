import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:isar/isar.dart';
import 'package:kero_space/features/health/data/models/health_collections.dart';
import 'package:kero_space/features/health/data/repositories/health_connect_repository.dart';
import 'package:kero_space/features/health/data/repositories/nutrition_repository.dart';
import 'package:kero_space/core/data/isar_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- EVENTS ---
abstract class HealthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadDashboard extends HealthEvent {}

class LogMeal extends HealthEvent {
  final MealEntry entry;
  LogMeal(this.entry);
  @override
  List<Object?> get props => [entry];
}

class ToggleFastingMode extends HealthEvent {
  final bool isFasting;
  ToggleFastingMode(this.isFasting);
  @override
  List<Object?> get props => [isFasting];
}

class UpdateProfile extends HealthEvent {
  final UserProfile profile;
  UpdateProfile(this.profile);
  @override
  List<Object?> get props => [profile];
}

class CreateCustomIngredient extends HealthEvent {
  final Ingredient ingredient;
  CreateCustomIngredient(this.ingredient);
  @override
  List<Object?> get props => [ingredient];
}

// --- STATE ---
enum HealthStatus { initial, loading, success, failure }

class HealthState extends Equatable {
  final HealthStatus status;
  final double steps;
  final double heartRate;
  final double sleepMinutes;
  
  final double dailyCalories;
  final double dailyProtein;
  final double dailyCarbs;
  final double dailyFat;
  
  final double dailyFiber;
  final double dailySugar;
  final double dailyFastCarbs;
  final double dailySlowCarbs;
  final double dailyFatSaturated;
  final double dailyFatUnsaturated;
  final double dailyCholesterol;
  final double dailySodium;
  
  final double bmrTarget;
  final bool isFastingMode;
  final List<MealEntry> todayMeals;
  
  final String? errorMessage;

  const HealthState({
    this.status = HealthStatus.initial,
    this.steps = 0,
    this.heartRate = 0,
    this.sleepMinutes = 0,
    this.dailyCalories = 0,
    this.dailyProtein = 0,
    this.dailyCarbs = 0,
    this.dailyFat = 0,
    this.dailyFiber = 0,
    this.dailySugar = 0,
    this.dailyFastCarbs = 0,
    this.dailySlowCarbs = 0,
    this.dailyFatSaturated = 0,
    this.dailyFatUnsaturated = 0,
    this.dailyCholesterol = 0,
    this.dailySodium = 0,
    this.bmrTarget = 2000,
    this.isFastingMode = false,
    this.todayMeals = const [],
    this.errorMessage,
  });

  HealthState copyWith({
    HealthStatus? status,
    double? steps,
    double? heartRate,
    double? sleepMinutes,
    double? dailyCalories,
    double? dailyProtein,
    double? dailyCarbs,
    double? dailyFat,
    double? dailyFiber,
    double? dailySugar,
    double? dailyFastCarbs,
    double? dailySlowCarbs,
    double? dailyFatSaturated,
    double? dailyFatUnsaturated,
    double? dailyCholesterol,
    double? dailySodium,
    double? bmrTarget,
    bool? isFastingMode,
    List<MealEntry>? todayMeals,
    bool clearError = false,
    String? errorMessage,
  }) {
    return HealthState(
      status: status ?? this.status,
      steps: steps ?? this.steps,
      heartRate: heartRate ?? this.heartRate,
      sleepMinutes: sleepMinutes ?? this.sleepMinutes,
      dailyCalories: dailyCalories ?? this.dailyCalories,
      dailyProtein: dailyProtein ?? this.dailyProtein,
      dailyCarbs: dailyCarbs ?? this.dailyCarbs,
      dailyFat: dailyFat ?? this.dailyFat,
      dailyFiber: dailyFiber ?? this.dailyFiber,
      dailySugar: dailySugar ?? this.dailySugar,
      dailyFastCarbs: dailyFastCarbs ?? this.dailyFastCarbs,
      dailySlowCarbs: dailySlowCarbs ?? this.dailySlowCarbs,
      dailyFatSaturated: dailyFatSaturated ?? this.dailyFatSaturated,
      dailyFatUnsaturated: dailyFatUnsaturated ?? this.dailyFatUnsaturated,
      dailyCholesterol: dailyCholesterol ?? this.dailyCholesterol,
      dailySodium: dailySodium ?? this.dailySodium,
      bmrTarget: bmrTarget ?? this.bmrTarget,
      isFastingMode: isFastingMode ?? this.isFastingMode,
      todayMeals: todayMeals ?? this.todayMeals,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status, steps, heartRate, sleepMinutes, dailyCalories, dailyProtein,
        dailyCarbs, dailyFat, dailyFiber, dailySugar, dailyFastCarbs, dailySlowCarbs,
        dailyFatSaturated, dailyFatUnsaturated, dailyCholesterol, dailySodium,
        bmrTarget, isFastingMode, todayMeals, errorMessage
      ];
}

// --- BLOC ---
@lazySingleton
class HealthBloc extends Bloc<HealthEvent, HealthState> {
  final HealthConnectRepository _healthRepo;
  final NutritionRepository _nutritionRepo;

  HealthBloc(this._healthRepo, this._nutritionRepo) : super(const HealthState()) {
    on<LoadDashboard>(_onLoadDashboard);
    on<LogMeal>(_onLogMeal);
    on<ToggleFastingMode>(_onToggleFastingMode);
    on<UpdateProfile>(_onUpdateProfile);
    on<CreateCustomIngredient>(_onCreateCustomIngredient);
  }

  Future<void> _onLoadDashboard(LoadDashboard event, Emitter<HealthState> emit) async {
    emit(state.copyWith(status: HealthStatus.loading));
    try {
      final prefs = await SharedPreferences.getInstance();
      final isFasting = prefs.getBool('fasting_mode') ?? false;

      // Ensure ingredients are seeded
      await _nutritionRepo.seedIngredientsIfNeeded();

      final isar = IsarService.instance;
      // Load latest biometrics for today
      final now = DateTime.now();
      // Sync biometrics non-blocking
      try {
        _healthRepo.syncBiometrics(now.subtract(const Duration(days: 1)), now);
      } catch (_) {}
      
      final startOfDay = DateTime(now.year, now.month, now.day);
      
      final stepsRecords = await isar.healthRecords.filter().typeEqualTo('STEPS').timestampGreaterThan(startOfDay).findAll();
      final hrRecords = await isar.healthRecords.filter().typeEqualTo('HEART_RATE').sortByTimestampDesc().findFirst();
      final sleepRecords = await isar.healthRecords.filter().typeEqualTo('SLEEP').sortByTimestampDesc().findFirst();
      
      double totalSteps = stepsRecords.fold(0.0, (sum, item) => sum + item.value);
      double latestHr = hrRecords?.value ?? 0.0;
      double latestSleep = sleepRecords?.value ?? 0.0;

      // Load nutrition
      final meals = await _nutritionRepo.getDailyMeals(now);
      double cals = 0, pro = 0, carbs = 0, fat = 0;
      double fiber = 0, sugar = 0, fastCarbs = 0, slowCarbs = 0;
      double fatSat = 0, fatUnsat = 0, chol = 0, sod = 0;
      
      for (var m in meals) {
        cals += m.calories.isNaN ? 0.0 : m.calories;
        pro += m.protein.isNaN ? 0.0 : m.protein;
        carbs += m.carbs.isNaN ? 0.0 : m.carbs;
        fat += m.fat.isNaN ? 0.0 : m.fat;
        fiber += m.fiber.isNaN ? 0.0 : m.fiber;
        sugar += m.sugar.isNaN ? 0.0 : m.sugar;
        fastCarbs += m.fastCarbs.isNaN ? 0.0 : m.fastCarbs;
        slowCarbs += m.slowCarbs.isNaN ? 0.0 : m.slowCarbs;
        fatSat += m.fatSaturated.isNaN ? 0.0 : m.fatSaturated;
        fatUnsat += m.fatUnsaturated.isNaN ? 0.0 : m.fatUnsaturated;
        chol += m.cholesterol.isNaN ? 0.0 : m.cholesterol;
        sod += m.sodium.isNaN ? 0.0 : m.sodium;
      }

      // Load BMR
      final profile = await isar.userProfiles.where().sortByTimestampDesc().findFirst();
      double bmr = profile?.bmrTarget ?? 2000.0;

      emit(state.copyWith(
        status: HealthStatus.success,
        steps: totalSteps,
        heartRate: latestHr,
        sleepMinutes: latestSleep,
        dailyCalories: cals,
        dailyProtein: pro,
        dailyCarbs: carbs,
        dailyFat: fat,
        dailyFiber: fiber,
        dailySugar: sugar,
        dailyFastCarbs: fastCarbs,
        dailySlowCarbs: slowCarbs,
        dailyFatSaturated: fatSat,
        dailyFatUnsaturated: fatUnsat,
        dailyCholesterol: chol,
        dailySodium: sod,
        bmrTarget: bmr,
        isFastingMode: isFasting,
        todayMeals: meals,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(status: HealthStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _onLogMeal(LogMeal event, Emitter<HealthState> emit) async {
    try {
      await _nutritionRepo.logMeal(event.entry);
      add(LoadDashboard());
    } catch (e) {
      emit(state.copyWith(status: HealthStatus.failure, errorMessage: 'Failed to log meal.'));
    }
  }

  Future<void> _onToggleFastingMode(ToggleFastingMode event, Emitter<HealthState> emit) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('fasting_mode', event.isFasting);
      emit(state.copyWith(isFastingMode: event.isFasting));
    } catch (e) {
      emit(state.copyWith(status: HealthStatus.failure, errorMessage: 'Failed to update fasting mode.'));
    }
  }

  Future<void> _onUpdateProfile(UpdateProfile event, Emitter<HealthState> emit) async {
    try {
      final isar = IsarService.instance;
      await isar.writeTxn(() async {
        await isar.userProfiles.put(event.profile);
      });
      add(LoadDashboard());
    } catch (e) {
      emit(state.copyWith(status: HealthStatus.failure, errorMessage: 'Failed to update profile.'));
    }
  }

  Future<void> _onCreateCustomIngredient(CreateCustomIngredient event, Emitter<HealthState> emit) async {
    try {
      await _nutritionRepo.addCustomIngredient(event.ingredient);
    } catch (e) {
      emit(state.copyWith(status: HealthStatus.failure, errorMessage: 'Failed to add ingredient.'));
    }
  }
}
