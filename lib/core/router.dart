import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/productivity/presentation/screens/productivity_screen.dart';
import '../features/productivity/presentation/screens/note_editor_screen.dart';
import '../features/productivity/data/models/productivity_collections.dart';

class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('Placeholder for $title')),
    );
  }
}

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const PlaceholderScreen(title: 'Home / Dashboard'),
    ),
    GoRoute(
      path: '/productivity',
      builder: (context, state) => const ProductivityScreen(),
    ),
    GoRoute(
      path: '/note_editor',
      builder: (context, state) {
        final note = state.extra as Note?;
        return NoteEditorScreen(existingNote: note);
      },
    ),
    GoRoute(
      path: '/health',
      builder: (context, state) => const PlaceholderScreen(title: 'Health'),
    ),
    GoRoute(
      path: '/finance',
      builder: (context, state) => const PlaceholderScreen(title: 'Finance'),
    ),
    GoRoute(
      path: '/church',
      builder: (context, state) => const PlaceholderScreen(title: 'Church'),
    ),
    GoRoute(
      path: '/telemetry',
      builder: (context, state) => const PlaceholderScreen(title: 'Telemetry'),
    ),
  ],
);
