import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/app_theme.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/theme/theme_state.dart';

class ThemePreviewScreen extends StatefulWidget {
  const ThemePreviewScreen({super.key});

  @override
  State<ThemePreviewScreen> createState() => _ThemePreviewScreenState();
}

class _ThemePreviewScreenState extends State<ThemePreviewScreen> {
  AppThemeId? _hoveredThemeId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) {
        final activeThemeId = state.selectedThemeId;
        final previewThemeId = _hoveredThemeId ?? activeThemeId;
        final isDark = state.themeMode == ThemeMode.dark ||
            (state.themeMode == ThemeMode.system &&
                MediaQuery.platformBrightnessOf(context) == Brightness.dark);

        final previewColors = AppTheme.getColorsFor(
          previewThemeId,
          isDark: isDark,
          customConfig: state.customConfig,
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text('Theme & Appearance'),
            actions: [
              IconButton(
                tooltip: 'Custom Studio',
                icon: const Icon(Icons.tune_rounded),
                onPressed: () => context.push('/settings/theme/studio'),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // Brightness Mode Selector
              _buildBrightnessSelector(context, state.themeMode),
              const SizedBox(height: 20),

              // Live Device Mockup Preview
              const Text(
                'LIVE DISPLAY PREVIEW',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              RepaintBoundary(
                child: _buildDeviceMockup(
                  previewColors: previewColors,
                  themeName: previewThemeId.displayName,
                  tag: previewThemeId.tag,
                  isDark: isDark,
                ),
              ),
              const SizedBox(height: 24),

              // Theme Collection Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'DEVELOPER THEMES',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => context.push('/settings/theme/studio'),
                    icon: const Icon(Icons.palette_outlined, size: 16),
                    label: const Text(
                      'Custom Studio',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 10 Theme Cards + Custom Card
              ...AppThemeId.values.map((themeId) {
                final isSelected = themeId == activeThemeId;
                final cardColors = AppTheme.getColorsFor(
                  themeId,
                  isDark: isDark,
                  customConfig: state.customConfig,
                );

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: _buildThemeCard(
                    context: context,
                    themeId: themeId,
                    isSelected: isSelected,
                    cardColors: cardColors,
                    onTap: () {
                      context.read<ThemeCubit>().selectTheme(themeId);
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          duration: const Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                          content: Text('Switched to ${themeId.displayName}'),
                          backgroundColor: cardColors.bgElevated,
                        ),
                      );
                    },
                    onCustomEdit: themeId == AppThemeId.custom
                        ? () => context.push('/settings/theme/studio')
                        : null,
                  ),
                );
              }),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBrightnessSelector(BuildContext context, ThemeMode mode) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle, width: 1),
      ),
      child: Row(
        children: [
          _buildSegmentItem(
            context: context,
            label: 'Dark',
            icon: Icons.dark_mode_rounded,
            isSelected: mode == ThemeMode.dark,
            onTap: () => context.read<ThemeCubit>().setThemeMode(ThemeMode.dark),
          ),
          _buildSegmentItem(
            context: context,
            label: 'Light',
            icon: Icons.light_mode_rounded,
            isSelected: mode == ThemeMode.light,
            onTap: () => context.read<ThemeCubit>().setThemeMode(ThemeMode.light),
          ),
          _buildSegmentItem(
            context: context,
            label: 'System',
            icon: Icons.brightness_auto_rounded,
            isSelected: mode == ThemeMode.system,
            onTap: () => context.read<ThemeCubit>().setThemeMode(ThemeMode.system),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentItem({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colors = context.appColors;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? colors.accentPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? (context.isDarkMode ? Colors.black : Colors.white)
                    : colors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? (context.isDarkMode ? Colors.black : Colors.white)
                      : colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceMockup({
    required AppThemeColors previewColors,
    required String themeName,
    required String tag,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: previewColors.bgBase,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: previewColors.borderSubtle, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: previewColors.accentPrimary.withValues(alpha: 0.08),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mock Phone Top Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: previewColors.accentPrimary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'TROBIO / LIFE-OS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: previewColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: previewColors.bgElevated,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: previewColors.borderSubtle, width: 1),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: previewColors.accentPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Mock Metric Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: previewColors.bgSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border(
                left: BorderSide(color: previewColors.accentPrimary, width: 3.5),
                top: BorderSide(color: previewColors.borderSubtle, width: 1),
                right: BorderSide(color: previewColors.borderSubtle, width: 1),
                bottom: BorderSide(color: previewColors.borderSubtle, width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HARDWARE & SERVICES',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: previewColors.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'All Daemons Online',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: previewColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: previewColors.accentPrimary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '99.9%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: previewColors.accentPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Mock Mini Action Grid
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: previewColors.bgSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: previewColors.borderSubtle, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.terminal_rounded, size: 16, color: previewColors.domainTelemetry),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Root Access',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: previewColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: previewColors.bgSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: previewColors.borderSubtle, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.bolt_rounded, size: 16, color: previewColors.accentPrimary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Overclock',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: previewColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeCard({
    required BuildContext context,
    required AppThemeId themeId,
    required bool isSelected,
    required AppThemeColors cardColors,
    required VoidCallback onTap,
    VoidCallback? onCustomEdit,
  }) {
    final colors = context.appColors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.bgSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? cardColors.accentPrimary : colors.borderSubtle,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: cardColors.accentPrimary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          themeId.tag,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: cardColors.accentPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        themeId.displayName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: cardColors.accentPrimary,
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
                    )
                  else if (onCustomEdit != null)
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      onPressed: onCustomEdit,
                      tooltip: 'Customize Palette',
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                themeId.tagline,
                style: TextStyle(
                  fontSize: 13,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),

              // Swatch Strip
              Row(
                children: [
                  _buildColorDot(cardColors.bgBase, 'Base'),
                  const SizedBox(width: 6),
                  _buildColorDot(cardColors.bgSurface, 'Surface'),
                  const SizedBox(width: 6),
                  _buildColorDot(cardColors.accentPrimary, 'Primary'),
                  const SizedBox(width: 6),
                  _buildColorDot(cardColors.accentSecondary, 'Secondary'),
                  const SizedBox(width: 6),
                  _buildColorDot(cardColors.textPrimary, 'Text'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorDot(Color color, String label) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24, width: 1),
      ),
    );
  }
}
