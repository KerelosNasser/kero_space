import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'dart:convert';
import '../../data/models/productivity_collections.dart';
import '../bloc/productivity_bloc.dart';

class NoteEditorScreen extends StatefulWidget {
  final Note? existingNote;
  final dynamic bloc; // Passed from productivity_screen.dart

  const NoteEditorScreen({super.key, this.existingNote, this.bloc});

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
              if (widget.bloc != null) {
                if (widget.existingNote != null) {
                  final updatedNote = widget.existingNote!
                    ..quillDelta = jsonStr
                    ..updatedAt = DateTime.now();
                  widget.bloc.add(ProductivityEvent.updateNote(updatedNote));
                } else {
                  final newNote = Note()
                    ..title = 'New Note'
                    ..quillDelta = jsonStr
                    ..deviceId = 'local'
                    ..platform = 'local'
                    ..createdAt = DateTime.now()
                    ..updatedAt = DateTime.now();
                  widget.bloc.add(ProductivityEvent.createNote(newNote));
                }
              }
              Navigator.of(context).pop();
            },
          )
        ],
      ),
      body: Column(
        children: [
          quill.QuillSimpleToolbar(
            controller: _controller,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
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
