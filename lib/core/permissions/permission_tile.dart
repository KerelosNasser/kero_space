import 'package:flutter/material.dart';
import 'package:kero_space/core/app_theme.dart';
import 'permission_item.dart';

class PermissionTile extends StatelessWidget {
  final PermissionItem item;
  final bool isGranted;
  final VoidCallback onRequest;

  const PermissionTile({
    super.key,
    required this.item,
    required this.isGranted,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGranted ? colors.accentSuccess.withValues(alpha: 0.4) : colors.borderSubtle,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isGranted ? colors.accentSuccess.withValues(alpha: 0.12) : colors.borderSubtle.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              item.icon,
              color: isGranted ? colors.accentSuccess : colors.accentWarning,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          if (isGranted)
            Icon(Icons.check_circle, color: colors.accentSuccess, size: 28)
          else
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accentWarning.withValues(alpha: 0.15),
                foregroundColor: colors.accentWarning,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onPressed: onRequest,
              child: const Text('Grant'),
            ),
        ],
      ),
    );
  }
}
