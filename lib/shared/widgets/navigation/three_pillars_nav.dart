import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/app_theme.dart';
import 'command_palette_modal.dart';

class ThreePillarsNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const ThreePillarsNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  bool get _isHome => currentIndex == 0;
  bool get _isLife => currentIndex >= 1 && currentIndex <= 3;
  bool get _isSystem => currentIndex >= 4 && currentIndex <= 5;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      decoration: BoxDecoration(
        color: colors.bgBase,
        border: Border(top: BorderSide(color: colors.borderSubtle, width: 1)),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        MediaQuery.of(context).padding.bottom > 0
            ? MediaQuery.of(context).padding.bottom
            : 10,
      ),
      child: Row(
        children: [
          // Pillar 1: Home
          Expanded(
            child: _buildPillarItem(
              context: context,
              icon: Icons.home_rounded,
              label: 'Home',
              sublabel: 'Focus',
              isActive: _isHome,
              accentColor: colors.accentPrimary,
              onTap: () => onTap(0),
            ),
          ),
          const SizedBox(width: 8),

          // Pillar 2: Life OS (Tasks 1, Health 2, Finance 3)
          Expanded(
            child: _buildPillarItem(
              context: context,
              icon: Icons.layers_rounded,
              label: 'Life OS',
              sublabel: _getLifeSublabel(),
              isActive: _isLife,
              accentColor: colors.domainProductivity,
              onTap: () {
                if (!_isLife) {
                  onTap(1); // Default to tasks
                } else {
                  _showSubMenu(
                    context: context,
                    title: 'Life OS Modules',
                    items: [
                      _SubMenuItem(title: 'Tasks & Notes', index: 1, icon: Icons.task_alt_rounded),
                      _SubMenuItem(title: 'Health & Vitals', index: 2, icon: Icons.favorite_rounded),
                      _SubMenuItem(title: 'Finance & EGX', index: 3, icon: Icons.account_balance_wallet_rounded),
                    ],
                  );
                }
              },
            ),
          ),
          const SizedBox(width: 8),

          // Pillar 3: System & Spirit (Church 4, Telemetry 5)
          Expanded(
            child: _buildPillarItem(
              context: context,
              icon: Icons.hub_rounded,
              label: 'System',
              sublabel: _getSystemSublabel(),
              isActive: _isSystem,
              accentColor: colors.domainTelemetry,
              onTap: () {
                if (!_isSystem) {
                  onTap(5); // Default to telemetry
                } else {
                  _showSubMenu(
                    context: context,
                    title: 'System & Spirit Modules',
                    items: [
                      _SubMenuItem(title: 'Church & Coptic', index: 4, icon: Icons.church_rounded),
                      _SubMenuItem(title: 'Device Telemetry', index: 5, icon: Icons.bar_chart_rounded),
                    ],
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getLifeSublabel() {
    switch (currentIndex) {
      case 1:
        return 'Tasks';
      case 2:
        return 'Health';
      case 3:
        return 'Finance';
      default:
        return 'Routine';
    }
  }

  String _getSystemSublabel() {
    switch (currentIndex) {
      case 4:
        return 'Church';
      case 5:
        return 'Telemetry';
      default:
        return 'Devices';
    }
  }

  Widget _buildPillarItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String sublabel,
    required bool isActive,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    final colors = context.appColors;

    return InkWell(
      onTap: onTap,
      onLongPress: () {
        HapticFeedback.mediumImpact();
        CommandPaletteModal.show(context, onSelectBranch: this.onTap);
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: isActive ? colors.bgSurface : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? accentColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: isActive ? accentColor : colors.textSecondary),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? colors.textPrimary : colors.textSecondary,
              ),
            ),
            Text(
              sublabel,
              style: TextStyle(
                fontSize: 10,
                color: isActive ? accentColor : colors.textDisabled,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSubMenu({
    required BuildContext context,
    required String title,
    required List<_SubMenuItem> items,
  }) {
    final colors = context.appColors;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.bgBase,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: colors.textSecondary,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    CommandPaletteModal.show(context, onSelectBranch: onTap);
                  },
                  icon: const Icon(Icons.search_rounded, size: 16),
                  label: const Text('Search', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: colors.accentPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...items.map((it) {
              final isSubSelected = it.index == currentIndex;
              return ListTile(
                leading: Icon(
                  it.icon,
                  color: isSubSelected ? colors.accentPrimary : colors.textSecondary,
                ),
                title: Text(
                  it.title,
                  style: TextStyle(
                    fontWeight: isSubSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSubSelected ? colors.textPrimary : colors.textSecondary,
                  ),
                ),
                trailing: isSubSelected
                    ? Icon(Icons.check_rounded, color: colors.accentPrimary, size: 20)
                    : null,
                onTap: () {
                  Navigator.of(context).pop();
                  onTap(it.index);
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _SubMenuItem {
  final String title;
  final int index;
  final IconData icon;

  const _SubMenuItem({
    required this.title,
    required this.index,
    required this.icon,
  });
}
