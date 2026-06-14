import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kero_space/core/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final Map<Permission, bool> _status = {
    Permission.notification: false,
    Permission.microphone: false,
  };

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final notif = await Permission.notification.isGranted;
    final mic = await Permission.microphone.isGranted;
    setState(() {
      _status[Permission.notification] = notif;
      _status[Permission.microphone] = mic;
    });
  }

  Future<void> _requestPermission(Permission p) async {
    await p.request();
    _checkPermissions();
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
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
                  const SizedBox(height: 48),
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
                  const SizedBox(height: 48),
                  
                  _buildPermissionTile(
                    title: 'Notifications',
                    description: 'Required to show the persistent background service and timer alerts.',
                    icon: Icons.notifications_active,
                    permission: Permission.notification,
                  ),
                  const SizedBox(height: 16),
                  _buildPermissionTile(
                    title: 'Microphone',
                    description: 'Required for the offline Wake Word detection. Audio never leaves your device.',
                    icon: Icons.mic,
                    permission: Permission.microphone,
                  ),
                  const SizedBox(height: 16),
                  
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.bgSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.bgElevated),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.settings_applications, color: AppTheme.accentGold),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Text('Advanced Permissions', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'App Usage & Accessibility permissions are required for the systemic blocker. You will be prompted for these in the settings when using those features.',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
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
                    foregroundColor: Colors.black,
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

  Widget _buildPermissionTile({
    required String title,
    required String description,
    required IconData icon,
    required Permission permission,
  }) {
    final isGranted = _status[permission] ?? false;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppTheme.bgElevated,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.accentGold),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          if (isGranted)
            const Icon(Icons.check_circle, color: Colors.green, size: 32)
          else
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: AppTheme.bgElevated,
                foregroundColor: AppTheme.accentGold,
              ),
              onPressed: () => _requestPermission(permission),
              child: const Text('Grant'),
            ),
        ],
      ),
    );
  }
}
