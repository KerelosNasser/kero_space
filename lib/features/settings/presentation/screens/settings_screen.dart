import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/data_export_service.dart';

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
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Backend Configuration', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _dockerUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Docker Server URL',
                    hintText: 'e.g. 192.168.1.100',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: _saveDockerUrl,
                ),
                const SizedBox(height: 8),
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
