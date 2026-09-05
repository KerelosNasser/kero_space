import 'package:flutter/material.dart';
import '../../../../core/app_theme.dart';
import 'command_palette_modal.dart';
import 'bento_hub_sheet.dart';

class BentoHubNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BentoHubNav({
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
        20,
        8,
        20,
        MediaQuery.of(context).padding.bottom > 0
            ? MediaQuery.of(context).padding.bottom
            : 10,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Home Quick Button
          InkWell(
            onTap: () => onTap(0),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.home_rounded,
                color: currentIndex == 0 ? colors.accentPrimary : colors.textSecondary,
              ),
            ),
          ),

          // Big Center Launch Hub Button
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.bgSurface,
                  foregroundColor: colors.textPrimary,
                  side: BorderSide(color: colors.accentPrimary, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onPressed: () => BentoHubSheet.show(
                  context,
                  currentIndex: currentIndex,
                  onSelectBranch: onTap,
                ),
                icon: Icon(Icons.dashboard_customize_rounded, color: colors.accentPrimary, size: 18),
                label: const Text(
                  'CONTROL HUB',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.0),
                ),
              ),
            ),
          ),

          // Command Search
          InkWell(
            onTap: () => CommandPaletteModal.show(context, onSelectBranch: onTap),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(Icons.search_rounded, color: colors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
