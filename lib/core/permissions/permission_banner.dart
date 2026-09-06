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
    final colors = context.appColors;
    return Container(
      color: colors.accentWarning,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: colors.bgSurface),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: colors.bgSurface, fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            TextButton(
              onPressed: onEnable,
              style: TextButton.styleFrom(
                foregroundColor: colors.bgSurface,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Text('Enable →', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            IconButton(
              icon: Icon(Icons.close, color: colors.bgSurface, size: 20),
              onPressed: onDismiss,
            ),
          ],
        ),
      ),
    );
  }
}
