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
}
