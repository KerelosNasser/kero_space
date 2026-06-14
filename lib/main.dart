import 'package:flutter/material.dart';
import 'core/app_theme.dart';
import 'core/router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'features/voice/presentation/bloc/voice_bloc.dart';
import 'features/voice/presentation/bloc/voice_state.dart';
import 'features/voice/presentation/widgets/voice_bottom_sheet.dart';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'core/data/isar_service.dart';
import 'core/di/injection.dart';
import 'package:kero_space/features/finance/data/repositories/notification_parser_service.dart';

import 'dart:io' show Platform;
import 'core/platform/windows/window_manager_service.dart';
import 'core/platform/windows/process_watcher_bloc.dart';
import 'core/platform/windows/process_watcher_event.dart';
import 'features/church/presentation/bloc/church_bloc.dart';
import 'features/church/data/models/mass_attendance.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dir = await getApplicationDocumentsDirectory();
  await IsarService.init(dir.path);

  // Set up dependency injection (GetIt)
  setupLocator();

  // Initialize background notification parser
  await NotificationParserService.initialize(IsarService.instance);

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

class KeroSpaceApp extends StatelessWidget {
  const KeroSpaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: getIt<VoiceBloc>()),
        if (Platform.isWindows)
          BlocProvider.value(value: getIt<ProcessWatcherBloc>()),
      ],
      child: MaterialApp.router(
        title: 'Kero Space',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        routerConfig: router,
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
        },
        actions: {
          ...WidgetsApp.defaultActions,
          NavigateToIntent: CallbackAction<NavigateToIntent>(
            onInvoke: (intent) => router.go(intent.route),
          ),
          MarkAttendanceGlobalIntent:
              CallbackAction<MarkAttendanceGlobalIntent>(
                onInvoke: (intent) {
                  getIt<ChurchBloc>().add(
                    MarkAttendanceEvent(DateTime.now(), AttendanceType.liturgy),
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
              if (state is VoiceWakeDetected) {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const VoiceBottomSheet(),
                );
              }
            },
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
