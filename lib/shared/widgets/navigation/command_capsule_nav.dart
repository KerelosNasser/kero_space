import 'package:flutter/material.dart';
import '../../../../core/app_theme.dart';
import 'command_palette_modal.dart';
import 'bento_hub_sheet.dart';

class CommandCapsuleNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CommandCapsuleNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      decoration: BoxDecoration(
        color: colors.bgBase,
        border: Border(top: BorderSide(color: colors.borderSubtle, width: 1)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        8,
        24,
        MediaQuery.of(context).padding.bottom > 0
            ? MediaQuery.of(context).padding.bottom
            : 12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Home
          _buildNavItem(
            context: context,
            icon: Icons.home_rounded,
            label: 'Home',
            isSelected: currentIndex == 0,
            onTap: () => onTap(0),
          ),

          // Center Command Pill (⌘)
          GestureDetector(
            onTap: () => CommandPaletteModal.show(context, onSelectBranch: onTap),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: colors.bgSurface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.6), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: colors.accentPrimary.withValues(alpha: 0.15),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.terminal_rounded, size: 18, color: colors.accentPrimary),
                  const SizedBox(width: 8),
                  Text(
                    '⌘ COMMAND',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Modules Hub
          _buildNavItem(
            context: context,
            icon: Icons.grid_view_rounded,
            label: 'All Apps',
            isSelected: currentIndex > 0,
            onTap: () => BentoHubSheet.show(
              context,
              currentIndex: currentIndex,
              onSelectBranch: onTap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colors = context.appColors;
    final color = isSelected ? colors.accentPrimary : colors.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
