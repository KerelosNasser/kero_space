import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/app_theme.dart';
import '../../../../core/navigation/navigation_mode.dart';
import '../../../../core/navigation/navigation_cubit.dart';
import '../../../../core/navigation/navigation_state.dart';

class NavigationSettingsScreen extends StatelessWidget {
  const NavigationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Navigation Systems'),
      ),
      body: BlocBuilder<NavigationCubit, NavigationState>(
        builder: (context, state) {
          final activeMode = state.mode;

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            children: [
              Text(
                'CHOOSE YOUR WORKFLOW',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Select the navigation paradigm that matches your daily routine. All screens and background states are preserved seamlessly.',
                style: TextStyle(fontSize: 13, color: colors.textSecondary, height: 1.35),
              ),
              const SizedBox(height: 18),

              ...AppNavStyle.values.map((mode) {
                final isSelected = mode == activeMode;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14.0),
                  child: _buildModeCard(
                    context: context,
                    mode: mode,
                    isSelected: isSelected,
                    onTap: () {
                      context.read<NavigationCubit>().setNavigationMode(mode);
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          duration: const Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                          content: Text('Switched navigation to ${mode.displayName}'),
                        ),
                      );
                    },
                  ),
                );
              }),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _buildModeCard({
    required BuildContext context,
    required AppNavStyle mode,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colors = context.appColors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.bgSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? colors.accentPrimary : colors.borderSubtle,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colors.accentPrimary.withValues(alpha: 0.15)
                              : colors.bgElevated,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          mode.icon,
                          size: 20,
                          color: isSelected ? colors.accentPrimary : colors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mode.displayName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                          ),
                          Text(
                            mode.tag,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: isSelected ? colors.accentPrimary : colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colors.accentPrimary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: context.isDarkMode ? Colors.black : Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'ACTIVE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: context.isDarkMode ? Colors.black : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                mode.tagline,
                style: TextStyle(fontSize: 13, color: colors.textSecondary),
              ),
              const SizedBox(height: 14),

              // Layout schematic illustration
              _buildSchematic(context, mode, isSelected),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSchematic(BuildContext context, AppNavStyle mode, bool isSelected) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.bgBase,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: _renderSchematicLayout(context, mode, isSelected),
    );
  }

  Widget _renderSchematicLayout(BuildContext context, AppNavStyle mode, bool isSelected) {
    final colors = context.appColors;
    final activeColor = isSelected ? colors.accentPrimary : colors.textSecondary;

    switch (mode) {
      case AppNavStyle.commandCapsule:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _schematicDot(Icons.home_rounded, 'Home', activeColor),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: colors.bgElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.6)),
              ),
              child: Row(
                children: [
                  Icon(Icons.terminal_rounded, size: 12, color: colors.accentPrimary),
                  const SizedBox(width: 4),
                  Text('⌘ COMMAND', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: colors.textPrimary)),
                ],
              ),
            ),
            _schematicDot(Icons.grid_view_rounded, 'Apps', colors.textDisabled),
          ],
        );

      case AppNavStyle.threePillars:
        return Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: colors.bgElevated,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(child: Text('HOME', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: activeColor))),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: colors.bgElevated,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(child: Text('LIFE OS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: colors.textSecondary))),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: colors.bgElevated,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(child: Text('SYSTEM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: colors.textSecondary))),
              ),
            ),
          ],
        );

      case AppNavStyle.floatingIsland:
        return Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: colors.bgSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.home_rounded, size: 14, color: activeColor),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.bgElevated,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('Active Pill ▾', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: colors.textPrimary)),
                ),
                const SizedBox(width: 8),
                Icon(Icons.terminal_rounded, size: 14, color: colors.textDisabled),
              ],
            ),
          ),
        );

      case AppNavStyle.bentoHub:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(Icons.home_rounded, size: 16, color: activeColor),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: colors.bgSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.accentPrimary),
              ),
              child: Text('CONTROL HUB', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: colors.accentPrimary)),
            ),
            Icon(Icons.search_rounded, size: 16, color: colors.textDisabled),
          ],
        );

      case AppNavStyle.classicBar:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Icon(Icons.home_rounded, size: 14, color: activeColor),
            Icon(Icons.task_alt_rounded, size: 14, color: colors.textDisabled),
            Icon(Icons.favorite_rounded, size: 14, color: colors.textDisabled),
            Icon(Icons.account_balance_wallet_rounded, size: 14, color: colors.textDisabled),
            Icon(Icons.church_rounded, size: 14, color: colors.textDisabled),
            Icon(Icons.bar_chart_rounded, size: 14, color: colors.textDisabled),
          ],
        );
    }
  }

  Widget _schematicDot(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }
}
