import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../../../core/di/injection.dart';
import '../../data/services/ai_service.dart';
import '../../data/models/productivity_collections.dart';
import '../bloc/productivity_bloc.dart';

class NoteEditorScreen extends StatefulWidget {
  final Note? existingNote;
  final dynamic bloc;

  const NoteEditorScreen({super.key, this.existingNote, this.bloc});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late final quill.QuillController _controller;
  late final TextEditingController _titleController;
  bool _isGeneratingTitle = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.existingNote?.title ?? '',
    );
    if (widget.existingNote != null) {
      final myJSON = jsonDecode(widget.existingNote!.quillDelta);
      _controller = quill.QuillController(
        document: quill.Document.fromJson(myJSON),
        selection: const TextSelection.collapsed(offset: 0),
      );
    } else {
      _controller = quill.QuillController.basic();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _generateAITitle() async {
    final text = _controller.document.toPlainText().trim();
    if (text.isEmpty) return;

    setState(() => _isGeneratingTitle = true);
    final aiService = getIt<AIService>();
    final newTitle = await aiService.generateNoteTitle(text);
    if (mounted) {
      setState(() {
        _titleController.text = newTitle;
        _isGeneratingTitle = false;
      });
    }
  }

  void _saveNote() async {
    final jsonStr = jsonEncode(_controller.document.toDelta().toJson());
    var finalTitle = _titleController.text.trim();
    
    if (finalTitle.isEmpty) {
      final text = _controller.document.toPlainText().trim();
      if (text.isNotEmpty) {
        final aiService = getIt<AIService>();
        finalTitle = await aiService.generateNoteTitle(text);
      } else {
        finalTitle = 'New Note';
      }
    }

    if (widget.bloc != null) {
      if (widget.existingNote != null) {
        final updatedNote = widget.existingNote!
          ..title = finalTitle
          ..quillDelta = jsonStr
          ..updatedAt = DateTime.now();
        widget.bloc.add(ProductivityEvent.updateNote(updatedNote));
      } else {
        final newNote = Note()
          ..title = finalTitle
          ..quillDelta = jsonStr
          ..deviceId = 'local'
          ..platform = 'local'
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();
        widget.bloc.add(ProductivityEvent.createNote(newNote));
      }
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = widget.existingNote != null 
      ? DateFormat('MMMM d, y • h:mm a').format(widget.existingNote!.updatedAt)
      : DateFormat('MMMM d, y • h:mm a').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Note'),
        actions: [
          if (_isGeneratingTitle)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20, 
                  height: 20, 
                  child: CircularProgressIndicator(strokeWidth: 2)
                )
              )
            ),
          if (!_isGeneratingTitle)
            IconButton(
              icon: const Icon(Icons.auto_awesome, color: Colors.amber),
              tooltip: "AI Generate Title",
              onPressed: _generateAITitle,
            ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveNote,
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _titleController,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    hintText: 'Title',
                    border: InputBorder.none,
                  ),
                ),
                Text(
                  dateStr,
                  style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6)),
                ),
                const SizedBox(height: 8),
                const Divider(),
              ],
            ),
          ),
          quill.QuillSimpleToolbar(
            controller: _controller,
            config: const quill.QuillSimpleToolbarConfig(
              multiRowsDisplay: false,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: quill.QuillEditor.basic(
                controller: _controller,
              ),
            ),
          )
        ],
      ),
    );
  }
}
