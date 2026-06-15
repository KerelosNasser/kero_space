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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGranted ? AppTheme.accentMint.withValues(alpha: 0.3) : AppTheme.bgElevated,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isGranted ? AppTheme.accentMint.withValues(alpha: 0.1) : AppTheme.bgElevated,
              shape: BoxShape.circle,
            ),
            child: Icon(
              item.icon,
              color: isGranted ? AppTheme.accentMint : AppTheme.accentGold,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          if (isGranted)
            const Icon(Icons.check_circle, color: AppTheme.accentMint, size: 28)
          else
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.bgElevated,
                foregroundColor: AppTheme.accentGold,
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
