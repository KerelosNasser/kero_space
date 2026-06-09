import 'package:flutter/material.dart';
import 'core/app_theme.dart';
import 'core/router.dart';

void main() {
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
