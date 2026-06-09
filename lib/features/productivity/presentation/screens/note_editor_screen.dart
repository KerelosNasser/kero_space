import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'dart:convert';
import '../../data/models/note_model.dart';

class NoteEditorScreen extends StatefulWidget {
  final Note? existingNote;

  const NoteEditorScreen({super.key, this.existingNote});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late final quill.QuillController _controller;

  @override
  void initState() {
    super.initState();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Note Editor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              // Save logic here
              final jsonStr = jsonEncode(_controller.document.toDelta().toJson());
              // Temporary save logic
              Navigator.of(context).pop();
            },
          )
        ],
      ),
      body: Column(
        children: [
          quill.QuillSimpleToolbar(
            controller: _controller,
            configurations: const quill.QuillSimpleToolbarConfigurations(),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: quill.QuillEditor.basic(
                controller: _controller,
                configurations: const quill.QuillEditorConfigurations(),
              ),
            ),
          )
        ],
      ),
    );
  }
}
