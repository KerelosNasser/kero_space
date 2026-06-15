import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:intl/intl.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:go_router/go_router.dart';
import '../../data/models/productivity_collections.dart';
import '../bloc/productivity_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kero_space/core/app_theme.dart';

class NotesMasonryGrid extends StatelessWidget {
  final List<Note> notes;

  const NotesMasonryGrid({super.key, required this.notes});

  String _extractPlainText(String quillDeltaJson) {
    try {
      final myJSON = jsonDecode(quillDeltaJson);
      final doc = quill.Document.fromJson(myJSON);
      final text = doc.toPlainText();
      return text.trim().isNotEmpty ? text.trim() : "Empty note";
    } catch (e) {
      return "Invalid content";
    }
  }

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) {
      return const Center(
        child: Text("No notes yet. Tap + to create one.", 
          style: TextStyle(color: Colors.grey)),
      );
    }

    return MasonryGridView.count(
      padding: const EdgeInsets.all(12),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        final plainText = _extractPlainText(note.quillDelta);
        final dateStr = DateFormat('MMM d, y • h:mm a').format(note.updatedAt);

        return GestureDetector(
          onTap: () => context.push('/note_editor', extra: {'note': note, 'bloc': context.read<ProductivityBloc>()}),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.accentCyan.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  note.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  plainText,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.8)),
                ),
                const SizedBox(height: 12),
                Text(
                  dateStr,
                  style: TextStyle(fontSize: 10, color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
