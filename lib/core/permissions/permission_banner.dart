import 'package:flutter/material.dart';
import '../app_theme.dart';

class PermissionBanner extends StatelessWidget {
  final String message;
  final VoidCallback onEnable;
  final VoidCallback onDismiss;

  const PermissionBanner({
    super.key,
    required this.message,
    required this.onEnable,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.accentGold,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppTheme.textPrimary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              ),
            ),
            TextButton(
              onPressed: onEnable,
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.textPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Text('Enable →'),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: AppTheme.textPrimary, size: 20),
              onPressed: onDismiss,
            ),
          ],
        ),
      ),
    );
  }
}
