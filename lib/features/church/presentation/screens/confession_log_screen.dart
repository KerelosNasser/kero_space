import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:go_router/go_router.dart';
import 'package:kero_space/core/app_theme.dart';
import '../bloc/confession_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../data/repositories/encrypted_confessions_repo.dart';
import '../../data/repositories/confession_crypto_service.dart';

class ConfessionLogScreen extends StatefulWidget {
  final EncryptedIsarConfessionsRepo repo;

  const ConfessionLogScreen({super.key, required this.repo});

  @override
  State<ConfessionLogScreen> createState() => _ConfessionLogScreenState();
}

class _ConfessionLogScreenState extends State<ConfessionLogScreen> with WidgetsBindingObserver {
  final QuillController _controller = QuillController.basic();
  List<Map<String, dynamic>> _pastConfessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadConfessions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      context.read<ConfessionBloc>().add(LockConfessionSession());
    }
  }

  Future<void> _loadConfessions() async {
    final state = context.read<ConfessionBloc>().state;
    if (state is ConfessionUnlocked) {
      final entries = await widget.repo.getConfessions(state.sessionKey);
      setState(() {
        _pastConfessions = entries;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveConfession() async {
    final state = context.read<ConfessionBloc>().state;
    if (state is ConfessionUnlocked && !_controller.document.isEmpty()) {
      final jsonDelta = jsonEncode(_controller.document.toDelta().toJson());
      await widget.repo.saveConfession(jsonDelta, state.sessionKey, DateTime.now());
      _controller.clear();
      _loadConfessions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ConfessionBloc, ConfessionState>(
      listener: (context, state) {
        if (state is ConfessionLocked) {
          context.go('/church');
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.bgPrimary,
        appBar: AppBar(
          title: const Text('Confessions Log', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
          backgroundColor: AppTheme.bgPrimary,
          iconTheme: const IconThemeData(color: AppTheme.textPrimary),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/church'),
          ),
          actions: [
            FutureBuilder<bool>(
              future: GetIt.I<ConfessionCryptoService>().isBiometricsEnabled(),
              builder: (context, snapshot) {
                final isBiometricEnabled = snapshot.data ?? false;
                if (!isBiometricEnabled) return const SizedBox.shrink();
                return IconButton(
                  icon: const Icon(Icons.fingerprint),
                  tooltip: 'Disable Biometric Unlock',
                  onPressed: () {
                    context.read<ConfessionBloc>().add(DisableBiometrics());
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Biometric unlock disabled')),
                    );
                    setState(() {});
                  },
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.lock_outline),
              tooltip: 'Lock Session',
              onPressed: () {
                context.read<ConfessionBloc>().add(LockConfessionSession());
              },
            ),
          ],
        ),
        body: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: AppTheme.accentViolet))
            : Column(
                children: [
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.bgSurface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            QuillSimpleToolbar(
                              controller: _controller,
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: QuillEditor.basic(
                                  controller: _controller,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentViolet),
                                  onPressed: _saveConfession,
                                  child: const Text('Save Encrypted', style: TextStyle(color: Colors.white)),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Divider(color: AppTheme.bgElevated),
                  Expanded(
                    flex: 1,
                    child: ListView.builder(
                      itemCount: _pastConfessions.length,
                      itemBuilder: (context, index) {
                        final entry = _pastConfessions[index];
                        final date = entry['date'] as DateTime;
                        Document? doc;
                        try {
                          final deltaJson = jsonDecode(entry['text']);
                          doc = Document.fromJson(deltaJson);
                        } catch (e) {
                          doc = Document()..insert(0, 'Failed to decode content');
                        }
                        
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.bgSurface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${date.toLocal()}'.split('.')[0], style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                              const SizedBox(height: 8),
                              QuillEditor.basic(
                                controller: QuillController(document: doc, selection: const TextSelection.collapsed(offset: 0), readOnly: true),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
