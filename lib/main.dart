import 'package:flutter/material.dart';
import 'core/app_theme.dart';
import 'core/router.dart';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'core/data/isar_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final dir = await getApplicationDocumentsDirectory();
  await IsarService.init(dir.path);
  
  const platform = MethodChannel('kero_space/main_methods');
  try {
    await platform.invokeMethod('startForegroundService');
  } on PlatformException catch (_) {
    debugPrint("Failed to start foreground service.");
  }

  runApp(const KeroSpaceApp());
}

class KeroSpaceApp extends StatelessWidget {
  const KeroSpaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Kero Space',
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
