import 'package:flutter/material.dart';
import '../../../../core/app_theme.dart';
import 'command_palette_modal.dart';
import 'bento_hub_sheet.dart';

class FloatingIslandDock extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const FloatingIslandDock({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  String _getActiveName() {
    switch (currentIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Tasks';
      case 2:
        return 'Health';
      case 3:
        return 'Finance';
      case 4:
        return 'Church';
      case 5:
        return 'Telemetry';
      default:
        return 'Home';
    }
  }

  IconData _getActiveIcon() {
    switch (currentIndex) {
      case 0:
        return Icons.home_rounded;
      case 1:
        return Icons.task_alt_rounded;
      case 2:
        return Icons.favorite_rounded;
      case 3:
        return Icons.account_balance_wallet_rounded;
      case 4:
        return Icons.church_rounded;
      case 5:
        return Icons.bar_chart_rounded;
      default:
        return Icons.home_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Center(
          heightFactor: 1.0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: colors.bgSurface,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: colors.borderSubtle, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Home Button
                IconButton(
                  icon: Icon(
                    Icons.home_rounded,
                    color: currentIndex == 0 ? colors.accentPrimary : colors.textSecondary,
                  ),
                  tooltip: 'Home',
                  onPressed: () => onTap(0),
                ),

                // Active Module Dynamic Pill
                GestureDetector(
                  onTap: () => BentoHubSheet.show(
                    context,
                    currentIndex: currentIndex,
                    onSelectBranch: onTap,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: colors.bgElevated,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colors.borderSubtle),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_getActiveIcon(), size: 16, color: colors.accentPrimary),
                        const SizedBox(width: 8),
                        Text(
                          _getActiveName(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.unfold_more_rounded, size: 14, color: colors.textDisabled),
                      ],
                    ),
                  ),
                ),

                // Quick Command Trigger
                IconButton(
                  icon: Icon(Icons.terminal_rounded, color: colors.textSecondary),
                  tooltip: 'Command Palette',
                  onPressed: () => CommandPaletteModal.show(context, onSelectBranch: onTap),
                ),

                // Bento Hub
                IconButton(
                  icon: Icon(Icons.grid_view_rounded, color: colors.textSecondary),
                  tooltip: 'All Apps',
                  onPressed: () => BentoHubSheet.show(
                    context,
                    currentIndex: currentIndex,
                    onSelectBranch: onTap,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
