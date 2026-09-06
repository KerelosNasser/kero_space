import 'package:flutter/material.dart';
import 'core/theme/theme_cubit.dart';
import 'core/theme/theme_state.dart';
import 'core/navigation/navigation_cubit.dart';
import 'core/router.dart';
import 'shared/widgets/navigation/command_palette_modal.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'features/voice/presentation/bloc/voice_bloc.dart';
import 'features/voice/presentation/bloc/voice_state.dart';
import 'features/voice/presentation/widgets/voice_bottom_sheet.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'core/data/isar_service.dart';
import 'core/di/injection.dart';
import 'package:kero_space/features/finance/data/repositories/notification_parser_service.dart';
import 'package:kero_space/features/finance/data/services/finance_worker.dart';
import 'package:kero_space/features/health/data/workers/health_sync_worker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'dart:io' show Platform;
import 'core/platform/windows/window_manager_service.dart';
import 'core/platform/windows/process_watcher_bloc.dart';
import 'core/platform/windows/process_watcher_event.dart';
import 'features/church/presentation/bloc/church_bloc.dart';
import 'features/church/data/models/mass_attendance.dart';
import 'features/church/data/services/church_notification_service.dart';

import 'features/voice/presentation/bloc/voice_event.dart';

class NavigateToIntent extends Intent {
  final String route;
  const NavigateToIntent(this.route);
}

class MarkAttendanceGlobalIntent extends Intent {
  const MarkAttendanceGlobalIntent();
}

class StartVoiceIntent extends Intent {
  const StartVoiceIntent();
}

class OpenCommandPaletteIntent extends Intent {
  const OpenCommandPaletteIntent();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  final dir = await getApplicationDocumentsDirectory();
  await IsarService.init(dir.path);

  // Set up dependency injection (GetIt)
  setupLocator();

  // Initialize background scraper worker
  FinanceWorker.initializeWorkmanager();
  FinanceWorker.scheduleDailyRefresh();

  // Initialize background health worker
  await HealthSyncWorker.initialize();
  await HealthSyncWorker.registerPeriodicTask();

  // Initialize background notification parser
  await getIt<NotificationParserService>().initialize(IsarService.instance);

  // Initialize church notifications
  try {
    await getIt<ChurchNotificationService>().init();
    await getIt<ChurchNotificationService>().scheduleSundayReminder();
    await getIt<ChurchNotificationService>().scheduleFastingReminder();
  } catch (e, st) {
    debugPrint("Failed to initialize church notifications: $e\n$st");
  }

  if (Platform.isWindows) {
    await WindowManagerService.init();
    getIt.registerSingleton<ProcessWatcherBloc>(
      ProcessWatcherBloc()..add(ProcessWatcherStarted()),
    );
  } else {
    const platform = MethodChannel('kero_space/main_methods');
    // Start foreground service asynchronously to prevent blocking the main UI thread during app startup.
    platform.invokeMethod('startForegroundService').catchError((e) {
      debugPrint("Failed to start foreground service: $e");
    });
  }

  runApp(const KeroSpaceApp());
}

class KeroSpaceApp extends StatefulWidget {
  const KeroSpaceApp({super.key});

  @override
  State<KeroSpaceApp> createState() => _KeroSpaceAppState();
}

class _KeroSpaceAppState extends State<KeroSpaceApp> {
  bool _isVoiceSheetOpen = false;

  void _showVoiceModal(BuildContext context) {
    if (_isVoiceSheetOpen) return;
    _isVoiceSheetOpen = true;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const VoiceBottomSheet(),
    ).whenComplete(() {
      _isVoiceSheetOpen = false;
      final current = getIt<VoiceBloc>().state;
      if (current is! VoiceIdle) {
        getIt<VoiceBloc>().add(CancelIntentEvent());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: getIt<ThemeCubit>()),
        BlocProvider.value(value: getIt<NavigationCubit>()),
        BlocProvider.value(value: getIt<VoiceBloc>()),
        if (Platform.isWindows)
          BlocProvider.value(value: getIt<ProcessWatcherBloc>()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeState>(
        buildWhen: (prev, curr) =>
            prev.selectedThemeId != curr.selectedThemeId ||
            prev.themeMode != curr.themeMode ||
            prev.customConfig != curr.customConfig,
        builder: (context, themeState) {
          return MaterialApp.router(
            title: 'Trobio',
            debugShowCheckedModeBanner: false,
            theme: themeState.lightThemeData,
            darkTheme: themeState.darkThemeData,
            themeMode: themeState.themeMode,
            routerConfig: router,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              quill.FlutterQuillLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en', 'US')],
            shortcuts: {
              ...WidgetsApp.defaultShortcuts,
              const SingleActivator(LogicalKeyboardKey.keyN, control: true):
                  const NavigateToIntent('/productivity'),
              const SingleActivator(
                LogicalKeyboardKey.keyM,
                control: true,
                shift: true,
              ): const MarkAttendanceGlobalIntent(),
              const SingleActivator(LogicalKeyboardKey.keyL, control: true):
                  const NavigateToIntent('/health/search'),
              const SingleActivator(LogicalKeyboardKey.slash, control: true):
                  const StartVoiceIntent(),
              const SingleActivator(LogicalKeyboardKey.keyK, control: true):
                  const OpenCommandPaletteIntent(),
              const SingleActivator(LogicalKeyboardKey.keyK, meta: true):
                  const OpenCommandPaletteIntent(),
            },
            actions: {
              ...WidgetsApp.defaultActions,
              NavigateToIntent: CallbackAction<NavigateToIntent>(
                onInvoke: (intent) => router.go(intent.route),
              ),
              OpenCommandPaletteIntent: CallbackAction<OpenCommandPaletteIntent>(
                onInvoke: (intent) {
                  final navContext = router.routerDelegate.navigatorKey.currentContext;
                  if (navContext != null) {
                    CommandPaletteModal.show(
                      navContext,
                      onSelectBranch: (i) {
                        switch (i) {
                          case 0:
                            router.go('/');
                            break;
                          case 1:
                            router.go('/productivity');
                            break;
                          case 2:
                            router.go('/health');
                            break;
                          case 3:
                            router.go('/finance');
                            break;
                          case 4:
                            router.go('/church');
                            break;
                          case 5:
                            router.go('/telemetry');
                            break;
                        }
                      },
                    );
                  }
                  return null;
                },
              ),
              MarkAttendanceGlobalIntent:
                  CallbackAction<MarkAttendanceGlobalIntent>(
                    onInvoke: (intent) {
                      getIt<ChurchBloc>().add(
                        MarkAttendanceEvent(DateTime.now(), ServiceType.liturgy),
                      );
                      return null;
                    },
                  ),
              StartVoiceIntent: CallbackAction<StartVoiceIntent>(
                onInvoke: (intent) {
                  getIt<VoiceBloc>().add(StartListeningEvent());
                  return null;
                },
              ),
            },
            builder: (context, child) {
              return BlocListener<VoiceBloc, VoiceState>(
                listener: (context, state) {
                  if (state is VoiceWakeDetected || state is VoiceListening) {
                    _showVoiceModal(context);
                  }
                },
                child: child ?? const SizedBox.shrink(),
              );
            },
          );
        },
      ),
    );
  }
}
