import 'dart:math';
import 'package:flutter/material.dart';
import 'package:kero_space/core/app_theme.dart';

class BypassPuzzleDialog extends StatefulWidget {
  const BypassPuzzleDialog({super.key});

  static Future<bool> show(BuildContext context) async =>
      await showDialog<bool>(context: context, barrierDismissible: false,
          builder: (_) => const BypassPuzzleDialog()) ?? false;

  @override
  State<BypassPuzzleDialog> createState() => _State();
}

class _State extends State<BypassPuzzleDialog> {
  late final int _a, _b, _answer;
  bool _revealed = true;
  final _ctrl = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _a = rng.nextInt(9) + 1;
    _b = rng.nextInt(9) + 1;
    _answer = _a + _b;
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _revealed = false);
    });
  }

  void _submit() {
    if (int.tryParse(_ctrl.text.trim()) == _answer) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _error = 'Wrong answer — try again');
      _ctrl.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Dialog(
      backgroundColor: colors.bgSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.lock_outline, color: colors.accentError, size: 36),
          const SizedBox(height: 12),
          Text(
            'Emergency Bypass',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Solve the puzzle. This action is logged.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 20),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              _revealed ? '$_a + $_b = ?' : '? + ? = ?',
              key: ValueKey(_revealed),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: _revealed ? colors.accentWarning : colors.textSecondary.withValues(alpha: 0.5),
                letterSpacing: 4,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            autofocus: true,
            style: TextStyle(color: colors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: 'Answer',
              errorText: _error,
              filled: true,
              fillColor: colors.bgElevated,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel'))),
            const SizedBox(width: 12),
            Expanded(child: FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(backgroundColor: colors.accentError),
              child: const Text('Bypass'),
            )),
          ]),
        ]),
      ),
    );
  }
}
