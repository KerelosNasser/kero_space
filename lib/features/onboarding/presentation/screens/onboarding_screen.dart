import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kero_space/core/app_theme.dart';
import 'package:kero_space/core/di/injection.dart';
import 'package:kero_space/core/permissions/permission_repository.dart';

import 'package:kero_space/core/permissions/permission_item.dart';
import 'package:kero_space/core/permissions/permission_tile.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with WidgetsBindingObserver {
  late final List<PermissionItem> _permissions;
  final Map<String, bool> _status = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final repo = getIt<PermissionRepository>();
    _permissions = [
      PermissionItem(
        title: 'Notifications',
        description: 'Required to show the persistent background service and timer alerts.',
        icon: Icons.notifications_active,
        check: () => Permission.notification.isGranted,
        request: () => Permission.notification.request().then((_) {}),
      ),
      PermissionItem(
        title: 'Microphone',
        description: 'Required for the offline Wake Word detection. Audio never leaves your device.',
        icon: Icons.mic,
        check: () => Permission.microphone.isGranted,
        request: () => Permission.microphone.request().then((_) {}),
      ),
      PermissionItem(
        title: 'Ignore Battery Optimizations',
        description: 'Prevents the OS from killing background monitoring agents.',
        icon: Icons.battery_saver,
        check: () => repo.hasBatteryOptimizationExemption(),
        request: () => repo.openBatteryOptimizationSettings(),
      ),
      PermissionItem(
        title: 'Accessibility Service',
        description: 'Required for the Mindless Scrolling Blocker overlay and Click Logger.',
        icon: Icons.accessibility_new,
        check: () => repo.hasAccessibilityService(),
        request: () => repo.openAccessibilitySettings(),
      ),
      PermissionItem(
        title: 'App Usage Access',
        description: 'Allows querying daily app usage stats to enforce blocker quotas.',
        icon: Icons.assessment_outlined,
        check: () => repo.hasUsageStats(),
        request: () => repo.openUsageStatsSettings(),
      ),
      PermissionItem(
        title: 'Notification Listener',
        description: 'Allows parsing transaction notifications to track expenses automatically.',
        icon: Icons.message_outlined,
        check: () => repo.hasNotificationListener(),
        request: () => repo.openNotificationListenerSettings(),
      ),
    ];

    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    final Map<String, bool> temp = {};
    for (final item in _permissions) {
      temp[item.title] = await item.check();
    }
    if (mounted) {
      setState(() {
        _status.clear();
        _status.addAll(temp);
      });
    }
  }

  Future<void> _requestPermission(PermissionItem item) async {
    await item.request();
    await _checkPermissions();
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);

    if (Platform.isAndroid) {
      const platform = MethodChannel('kero_space/main_methods');
      try {
        await platform.invokeMethod('startForegroundService');
      } catch (e) {
        debugPrint("Failed to start foreground service: $e");
      }
    }

    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24.0),
                children: [
                  const SizedBox(height: 24),
                  const Icon(Icons.shield_outlined, size: 80, color: AppTheme.accentGold),
                  const SizedBox(height: 24),
                  const Text(
                    'Welcome to Kero Space',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 32, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'To provide the Omniscient Layer experience, we need a few permissions.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ..._permissions.map((p) => PermissionTile(
                        item: p,
                        isGranted: _status[p.title] ?? false,
                        onRequest: () => _requestPermission(p),
                      )),
                  const SizedBox(height: 100), // padding for the bottom button
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentGold,
                    foregroundColor: AppTheme.bgPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _finishOnboarding,
                  child: const Text('Continue to App', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


}
