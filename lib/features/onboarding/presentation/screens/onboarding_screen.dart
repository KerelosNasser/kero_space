import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kero_space/core/app_theme.dart';
import 'package:kero_space/core/di/injection.dart';
import 'package:kero_space/core/permissions/permission_repository.dart';

class PermissionItem {
  final String title;
  final String description;
  final IconData icon;
  final Future<bool> Function() check;
  final Future<void> Function() request;

  PermissionItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.check,
    required this.request,
  });
}

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
                  ..._permissions.map((p) => _buildPermissionTile(p)),
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

  Widget _buildPermissionTile(PermissionItem item) {
    final isGranted = _status[item.title] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGranted ? AppTheme.accentMint.withValues(alpha: 0.3) : AppTheme.bgElevated,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isGranted ? AppTheme.accentMint.withValues(alpha: 0.1) : AppTheme.bgElevated,
              shape: BoxShape.circle,
            ),
            child: Icon(
              item.icon,
              color: isGranted ? AppTheme.accentMint : AppTheme.accentGold,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          if (isGranted)
            const Icon(Icons.check_circle, color: AppTheme.accentMint, size: 28)
          else
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.bgElevated,
                foregroundColor: AppTheme.accentGold,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onPressed: () => _requestPermission(item),
              child: const Text('Grant'),
            ),
        ],
      ),
    );
  }
}
