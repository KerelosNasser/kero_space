import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../bloc/confession_bloc.dart';
import '../../data/repositories/encrypted_confessions_repo.dart';

class ConfessionLogScreen extends StatefulWidget {
  final EncryptedIsarConfessionsRepo repo;

  const ConfessionLogScreen({super.key, required this.repo});

  @override
  State<ConfessionLogScreen> createState() => _ConfessionLogScreenState();
}

class _ConfessionLogScreenState extends State<ConfessionLogScreen> {
  final QuillController _controller = QuillController.basic();
  List<Map<String, dynamic>> _pastConfessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConfessions();
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
          Navigator.of(context).pushReplacementNamed('/confession_auth');
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('Confessions Log', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.lock_outline),
              onPressed: () {
                context.read<ConfessionBloc>().add(LockConfessionSession());
              },
            )
          ],
        ),
        body: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFBF5AF2)))
            : Column(
                children: [
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C1E),
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
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFBF5AF2)),
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
                  const Divider(color: Color(0xFF38383A)),
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
                            color: const Color(0xFF1C1C1E),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${date.toLocal()}'.split('.')[0], style: const TextStyle(color: Colors.grey, fontSize: 12)),
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
