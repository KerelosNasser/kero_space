import 'package:flutter/material.dart';
import '../data/data_export_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isExporting = false;
  final DataExportService _exportService = DataExportService();

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
        SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Export My Data'),
            subtitle: const Text('Download a JSON copy of all non-encrypted data'),
            trailing: _isExporting ? const CircularProgressIndicator() : null,
            onTap: _isExporting ? null : _exportData,
          ),
        ],
      ),
    );
  }
}
