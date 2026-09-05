import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/data_export_service.dart';
import '../../../../core/app_theme.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/theme/theme_state.dart';
import '../../../../core/navigation/navigation_cubit.dart';
import '../../../../core/navigation/navigation_state.dart';
import '../../../../core/navigation/navigation_mode.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isExporting = false;
  final DataExportService _exportService = DataExportService();
  final TextEditingController _dockerUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dockerUrlController.text = prefs.getString('docker_url') ?? '';
    });
  }

  @override
  void dispose() {
    _dockerUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveDockerUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('docker_url', url);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Docker URL saved')),
      );
    }
  }

  Future<void> _exportData() async {
    setState(() => _isExporting = true);
    try {
      final path = await _exportService.exportData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Data exported to $path')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: context.appColors.accentError,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Appearance & Themes
          BlocBuilder<ThemeCubit, ThemeState>(
            builder: (context, themeState) {
              final activeTheme = themeState.selectedThemeId;
              final modeName = themeState.themeMode == ThemeMode.dark
                  ? 'Dark'
                  : (themeState.themeMode == ThemeMode.light ? 'Light' : 'System');

              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.accentPrimary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.palette_rounded, color: colors.accentPrimary, size: 20),
                ),
                title: const Text(
                  'Appearance & Developer Themes',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text('${activeTheme.displayName} • $modeName Mode'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: colors.bgElevated,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: colors.borderSubtle),
                      ),
                      child: Text(
                        activeTheme.tag,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: colors.accentPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, size: 20),
                  ],
                ),
                onTap: () => context.push('/settings/theme'),
              );
            },
          ),
          const Divider(),

          // Navigation System Selector
          BlocBuilder<NavigationCubit, NavigationState>(
            builder: (context, navState) {
              final activeMode = navState.mode;

              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.accentSecondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(activeMode.icon, color: colors.accentSecondary, size: 20),
                ),
                title: const Text(
                  'Navigation System',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(activeMode.displayName),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: colors.bgElevated,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: colors.borderSubtle),
                      ),
                      child: Text(
                        activeMode.tag,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: colors.accentSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, size: 20),
                  ],
                ),
                onTap: () => context.push('/settings/navigation'),
              );
            },
          ),
          const Divider(),

          // Voice Assistant & Wake Word
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.accentPrimary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.mic_rounded, color: colors.accentPrimary, size: 20),
            ),
            title: const Text(
              'Voice Assistant & Wake Word',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text('“Hey Trobio” hotword, assistant role & voice match'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colors.bgElevated,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: colors.borderSubtle),
                  ),
                  child: Text(
                    'HEY TROBIO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: colors.accentPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, size: 20),
              ],
            ),
            onTap: () => context.push('/settings/voice'),
          ),
          const Divider(),

          // Data Export
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.accentSecondary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.download_rounded, color: colors.accentSecondary, size: 20),
            ),
            title: const Text('Export My Data', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Download a JSON copy of non-encrypted data'),
            trailing: _isExporting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.chevron_right, size: 20),
            onTap: _isExporting ? null : _exportData,
          ),
          const Divider(),

          // Backend Configuration
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BACKEND CONFIGURATION',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _dockerUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Docker Server URL',
                    hintText: 'e.g. 192.168.1.100',
                  ),
                  onSubmitted: _saveDockerUrl,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => _saveDockerUrl(_dockerUrlController.text),
                  child: const Text('Save URL'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

