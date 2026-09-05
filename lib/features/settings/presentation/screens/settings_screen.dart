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
import '../../../../core/data/sync_worker.dart';
import '../../../../core/data/sync_outbox_repository.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isExporting = false;
  bool _isSyncing = false;
  int _pendingSyncCount = 0;
  String? _lastSyncMessage;
  final DataExportService _exportService = DataExportService();
  final TextEditingController _dockerUrlController = TextEditingController();
  final SyncOutboxRepository _syncRepo = SyncOutboxRepository();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final pendingCount = await _syncRepo.getPendingCount();
    setState(() {
      _dockerUrlController.text = prefs.getString('docker_url') ?? '';
      _pendingSyncCount = pendingCount;
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

  Future<void> _triggerSyncNow() async {
    setState(() => _isSyncing = true);
    try {
      final result = await SyncWorker.triggerSync(
        dockerUrl: _dockerUrlController.text,
      );

      final updatedCount = await _syncRepo.getPendingCount();

      if (!mounted) return;

      setState(() {
        _pendingSyncCount = updatedCount;
        _lastSyncMessage = result.success
            ? 'Synced ${result.syncedCount} records successfully'
            : (result.errorMessage ?? 'Sync failed');
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_lastSyncMessage!),
          backgroundColor: result.success
              ? context.appColors.accentSuccess
              : context.appColors.accentError,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _lastSyncMessage = 'Sync failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sync failed: $e'),
          backgroundColor: context.appColors.accentError,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
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
                  'BACKEND CONFIGURATION & SYNC',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.bgSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.cloud_sync_rounded,
                                color: colors.accentPrimary,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Sync Status',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _pendingSyncCount > 0
                                  ? colors.accentWarning.withValues(alpha: 0.15)
                                  : colors.accentSuccess.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _pendingSyncCount > 0
                                  ? '$_pendingSyncCount Pending'
                                  : 'Up to date',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _pendingSyncCount > 0
                                    ? colors.accentWarning
                                    : colors.accentSuccess,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_lastSyncMessage != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _lastSyncMessage!,
                          style: TextStyle(fontSize: 12, color: colors.textSecondary),
                        ),
                      ],
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isSyncing ? null : _triggerSyncNow,
                          icon: _isSyncing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.sync, size: 18),
                          label: Text(_isSyncing ? 'Syncing...' : 'Sync Now'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _dockerUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Docker Server URL',
                    hintText: 'e.g. 192.168.1.100 or localhost',
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

