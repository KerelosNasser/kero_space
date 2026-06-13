import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:kero_space/core/data/isar_service.dart';
import 'package:kero_space/features/church/data/repositories/church_repository.dart';
import 'package:kero_space/features/church/data/repositories/confession_crypto_service.dart';
import 'package:kero_space/features/church/data/repositories/encrypted_confessions_repo.dart';
import 'package:kero_space/features/church/presentation/bloc/church_bloc.dart';
import 'package:kero_space/features/church/presentation/bloc/confession_bloc.dart';

// Health module
import 'package:kero_space/features/health/data/repositories/health_connect_repository.dart';
import 'package:kero_space/features/health/data/repositories/nutrition_repository.dart';
import 'package:kero_space/features/health/presentation/bloc/health_bloc.dart';

// Finance module
import 'package:kero_space/features/finance/data/repositories/finance_repository.dart';
import 'package:kero_space/features/finance/data/repositories/egx_scraper_service.dart';
import 'package:kero_space/features/finance/presentation/bloc/finance_bloc.dart';

// Telemetry module
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kero_space/core/data/kero_space_platform_service.dart';
import 'package:kero_space/features/telemetry/data/repositories/screen_event_repository.dart';
import 'package:kero_space/features/telemetry/data/repositories/app_usage_repository.dart';
import 'package:kero_space/features/telemetry/data/repositories/click_log_repository.dart';
import 'package:kero_space/features/telemetry/data/repositories/blacklist_repository.dart';
import 'package:kero_space/features/telemetry/presentation/bloc/telemetry_bloc.dart';

final getIt = GetIt.instance;

void setupLocator() {
  // Common
  getIt.registerLazySingleton<Dio>(() => Dio());

  // Health
  getIt.registerLazySingleton<HealthConnectRepository>(
    () => HealthConnectRepository(),
  );
  getIt.registerLazySingleton<NutritionRepository>(() => NutritionRepository());
  getIt.registerFactory<HealthBloc>(
    () => HealthBloc(
      getIt<HealthConnectRepository>(),
      getIt<NutritionRepository>(),
    ),
  );

  // Finance
  getIt.registerLazySingleton<FinanceRepository>(
    () => FinanceRepository(IsarService.instance),
  );
  getIt.registerLazySingleton<EGXScraperService>(
    () => EGXScraperService(dio: getIt<Dio>()),
  );
  getIt.registerFactory<FinanceBloc>(
    () => FinanceBloc(
      financeRepository: getIt<FinanceRepository>(),
      egxScraperService: getIt<EGXScraperService>(),
      nutritionRepository: getIt<NutritionRepository>(),
    ),
  );

  // Church
  getIt.registerLazySingleton<ChurchRepository>(
    () => ChurchRepository(IsarService.instance),
  );
  getIt.registerLazySingleton<ConfessionCryptoService>(
    () => ConfessionCryptoService(),
  );
  getIt.registerLazySingleton<EncryptedIsarConfessionsRepo>(
    () => EncryptedIsarConfessionsRepo(
      IsarService.instance,
      getIt<ConfessionCryptoService>(),
    ),
  );
  getIt.registerFactory<ChurchBloc>(
    () => ChurchBloc(getIt<ChurchRepository>()),
  );
  getIt.registerFactory<ConfessionBloc>(
    () => ConfessionBloc(
      getIt<ConfessionCryptoService>(),
    ),
  );

  // Telemetry
  getIt.registerLazySingleton<FlutterSecureStorage>(() => const FlutterSecureStorage());
  getIt.registerLazySingleton<KeroSpacePlatformService>(() => KeroSpacePlatformService());
  getIt.registerLazySingleton<ScreenEventRepository>(
      () => ScreenEventRepository(IsarService.instance));
  getIt.registerLazySingleton<AppUsageRepository>(
      () => AppUsageRepository(IsarService.instance));
  getIt.registerLazySingleton<ClickLogRepository>(
      () => ClickLogRepository(IsarService.instance));
  getIt.registerLazySingleton<BlacklistRepository>(
      () => BlacklistRepository(getIt<FlutterSecureStorage>()));
  getIt.registerFactory<TelemetryBloc>(() => TelemetryBloc(
    getIt<ScreenEventRepository>(),
    getIt<AppUsageRepository>(),
    getIt<ClickLogRepository>(),
    getIt<BlacklistRepository>(),
    getIt<KeroSpacePlatformService>(),
  ));
}
