import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:kero_space/core/data/isar_service.dart';
import 'package:kero_space/core/permissions/permission_repository.dart';

// Productivity module
import 'package:kero_space/features/productivity/data/repositories/productivity_repository.dart';
import 'package:kero_space/features/productivity/data/repositories/local_calendar_repository.dart';
import 'package:kero_space/features/productivity/presentation/bloc/productivity_bloc.dart';
import 'package:kero_space/features/productivity/presentation/bloc/calendar_bloc.dart';
import 'package:kero_space/features/productivity/data/services/ai_service.dart';

// Church module
import 'package:kero_space/features/church/data/repositories/church_repository.dart';
import 'package:kero_space/features/church/data/repositories/confession_crypto_service.dart';
import 'package:kero_space/features/church/data/repositories/encrypted_confessions_repo.dart';
import 'package:kero_space/features/church/presentation/bloc/church_bloc.dart';
import 'package:kero_space/features/church/presentation/bloc/confession_bloc.dart';
import 'package:kero_space/features/church/presentation/bloc/coptic_bloc.dart';
import 'package:kero_space/features/church/data/services/youversion_service.dart';
import 'package:kero_space/features/church/data/services/church_notification_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Health module
import 'package:kero_space/features/health/data/repositories/health_connect_repository.dart';
import 'package:kero_space/features/health/data/repositories/nutrition_repository.dart';
import 'package:kero_space/features/health/presentation/bloc/health_bloc.dart';
import 'package:kero_space/features/health/data/services/barcode_service.dart';
import 'package:kero_space/features/health/data/services/ai_scanner_service.dart';
import 'package:kero_space/features/exercises/data/repositories/exercises_repository.dart';
import 'package:kero_space/features/exercises/presentation/bloc/exercise_bloc.dart';

// Finance module
import 'package:kero_space/features/finance/data/repositories/finance_repository.dart';
import 'package:kero_space/features/finance/data/repositories/egx_scraper_service.dart';
import 'package:kero_space/features/finance/data/repositories/notification_parser_service.dart';
import 'package:kero_space/features/finance/data/services/finance_notification_service.dart';
import 'package:kero_space/features/finance/data/services/finance_ai_service.dart';
import 'package:kero_space/features/finance/presentation/bloc/finance_bloc.dart';

// Voice module
import 'package:kero_space/features/voice/domain/command_parser.dart';
import 'package:kero_space/features/voice/presentation/bloc/voice_bloc.dart';

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
  getIt.registerLazySingleton<PermissionRepository>(
    () => PermissionRepository(),
  );

  // Productivity
  getIt.registerLazySingleton<ProductivityRepository>(
    () => ProductivityRepository(),
  );
  getIt.registerLazySingleton<LocalCalendarRepository>(
    () => LocalCalendarRepository(),
  );
  getIt.registerLazySingleton<ProductivityBloc>(
    () => ProductivityBloc(getIt<ProductivityRepository>()),
  );
  getIt.registerLazySingleton<CalendarBloc>(
    () => CalendarBloc(getIt<LocalCalendarRepository>()),
  );
  getIt.registerLazySingleton<AIService>(() => AIService());

  // Health
  getIt.registerLazySingleton<HealthConnectRepository>(
    () => HealthConnectRepository(),
  );
  getIt.registerLazySingleton<NutritionRepository>(() => NutritionRepository());
  getIt.registerLazySingleton<BarcodeService>(
    () => BarcodeService(getIt<Dio>()),
  );
  getIt.registerLazySingleton<AiScannerService>(
    () => AiScannerService(getIt<Dio>()),
  );
  getIt.registerLazySingleton<ExercisesRepository>(() => ExercisesRepository());
  getIt.registerLazySingleton<HealthBloc>(
    () => HealthBloc(
      getIt<HealthConnectRepository>(),
      getIt<NutritionRepository>(),
    ),
  );
  getIt.registerFactory<ExerciseBloc>(
    () => ExerciseBloc(getIt<ExercisesRepository>()),
  );

  // Finance
  getIt.registerLazySingleton<FinanceRepository>(
    () => FinanceRepository(IsarService.instance),
  );
  getIt.registerLazySingleton<EGXScraperService>(
    () => EGXScraperService(dio: getIt<Dio>()),
  );
  getIt.registerLazySingleton<FinanceNotificationService>(
    () => FinanceNotificationService(),
  );
  getIt.registerLazySingleton<FinanceAIService>(
    () => FinanceAIService(dio: getIt<Dio>()),
  );
  getIt.registerLazySingleton<FinanceBloc>(
    () => FinanceBloc(
      financeRepository: getIt<FinanceRepository>(),
      egxScraperService: getIt<EGXScraperService>(),
      notificationService: getIt<FinanceNotificationService>(),
      financeAiService: getIt<FinanceAIService>(),
    ),
  );
  getIt.registerLazySingleton<NotificationParserService>(
    () => NotificationParserService(),
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
  getIt.registerLazySingleton<ChurchBloc>(
    () => ChurchBloc(getIt<ChurchRepository>()),
  );
  getIt.registerLazySingleton<ConfessionBloc>(
    () => ConfessionBloc(getIt<ConfessionCryptoService>()),
  );
  getIt.registerLazySingleton<YouVersionService>(
    () => YouVersionService(
      dio: getIt<Dio>(),
      apiKey: dotenv.env['YOUVERSION_API_KEY'],
    ),
  );
  getIt.registerLazySingleton<CopticBloc>(
    () => CopticBloc(youVersion: getIt<YouVersionService>()),
  );

  getIt.registerLazySingleton<ChurchNotificationService>(
    () => ChurchNotificationService(),
  );

  // Voice
  getIt.registerLazySingleton<CommandParser>(() => CommandParser());
  getIt.registerLazySingleton<VoiceBloc>(
    () => VoiceBloc(getIt<CommandParser>()),
  );

  // Telemetry
  getIt.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );
  getIt.registerLazySingleton<KeroSpacePlatformService>(
    () => KeroSpacePlatformService(),
  );
  getIt.registerLazySingleton<ScreenEventRepository>(
    () => ScreenEventRepository(IsarService.instance),
  );
  getIt.registerLazySingleton<AppUsageRepository>(
    () => AppUsageRepository(IsarService.instance),
  );
  getIt.registerLazySingleton<ClickLogRepository>(
    () => ClickLogRepository(IsarService.instance),
  );
  getIt.registerLazySingleton<BlacklistRepository>(
    () => BlacklistRepository(getIt<FlutterSecureStorage>()),
  );
  getIt.registerLazySingleton<TelemetryBloc>(
    () => TelemetryBloc(
      getIt<ScreenEventRepository>(),
      getIt<AppUsageRepository>(),
      getIt<ClickLogRepository>(),
      getIt<BlacklistRepository>(),
      getIt<KeroSpacePlatformService>(),
    ),
  );
}
