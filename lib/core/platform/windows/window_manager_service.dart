import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:system_tray/system_tray.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/router.dart';
import '../../../../features/church/presentation/bloc/church_bloc.dart';
import '../../../../features/church/data/models/mass_attendance.dart';

class WindowManagerService {
  static Future<void> init() async {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      titleBarStyle: TitleBarStyle.hidden,
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.setPreventClose(true); // intercept close -> minimize to tray
    });

    final tray = SystemTray();
    try {
      await tray.initSystemTray(iconPath: 'assets/icons/tray.ico');
      final menu = Menu();
      await menu.buildFrom([
        MenuItemLabel(label: 'Open Kero Space', onClicked: (_) => windowManager.show()),
        MenuItemLabel(label: 'New Task (Ctrl+N)', onClicked: (_) => router.go('/productivity')),
        MenuItemLabel(label: 'Mark Mass (Ctrl+Shift+M)', onClicked: (_) => getIt<ChurchBloc>().add(MarkAttendanceEvent(DateTime.now(), AttendanceType.liturgy))),
        MenuSeparator(),
        MenuItemLabel(label: 'Exit', onClicked: (_) => windowManager.destroy()),
      ]);
      await tray.setContextMenu(menu);

      // Handle tray icon click
      tray.registerSystemTrayEventHandler((eventName) {
        if (eventName == kSystemTrayEventClick) {
          windowManager.show();
        }
      });
    } catch (e) {
      // Tray icon might be missing or unsupported, silently continue
      debugPrint("SystemTray init failed: \$e");
    }
  }
}
