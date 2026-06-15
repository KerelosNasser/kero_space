import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kero_space/core/app_theme.dart';

class CommandHintTicker extends StatefulWidget {
  const CommandHintTicker({super.key});

  @override
  State<CommandHintTicker> createState() => _CommandHintTickerState();
}

class _CommandHintTickerState extends State<CommandHintTicker> {
  final List<String> hints = [
    'try: "todo: shower daily"',
    'try: "expense: 200 groceries"',
    'try: "note: buy some milk"',
    'try: "meal: 200g chicken"',
    'try: "mark attendance"',
  ];

  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % hints.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: Text(
        hints[_currentIndex],
        key: ValueKey<int>(_currentIndex),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppTheme.textSecondary,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
