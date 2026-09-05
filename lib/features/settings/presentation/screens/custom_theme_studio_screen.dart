import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/app_theme.dart';
import '../../../../core/theme/custom_theme_config.dart';
import '../../../../core/theme/theme_cubit.dart';

class CustomThemeStudioScreen extends StatefulWidget {
  const CustomThemeStudioScreen({super.key});

  @override
  State<CustomThemeStudioScreen> createState() => _CustomThemeStudioScreenState();
}

class _CustomThemeStudioScreenState extends State<CustomThemeStudioScreen> {
  late bool _isDark;
  late Color _bgPrimary;
  late Color _bgSurface;
  late Color _accentPrimary;
  late Color _accentSecondary;

  final List<Color> _bgDarkPresets = const [
    Color(0xFF0A0A0C),
    Color(0xFF121214),
    Color(0xFF14171C),
    Color(0xFF1D2021),
    Color(0xFF000000),
    Color(0xFF00212B),
    Color(0xFF101017),
    Color(0xFF08121E),
    Color(0xFF181825),
  ];

  final List<Color> _bgLightPresets = const [
    Color(0xFFF3F3F1),
    Color(0xFFF5F5F7),
    Color(0xFFECEFF4),
    Color(0xFFFBF1C7),
    Color(0xFFFAFAFA),
    Color(0xFFFDF6E3),
    Color(0xFFE1E2E7),
    Color(0xFFE8F1F5),
    Color(0xFFEFF1F5),
  ];

  final List<Color> _surfaceDarkPresets = const [
    Color(0xFF141417),
    Color(0xFF1C1C20),
    Color(0xFF1C2128),
    Color(0xFF282828),
    Color(0xFF111111),
    Color(0xFF073642),
    Color(0xFF161622),
    Color(0xFF0F2034),
    Color(0xFF1E1E2E),
  ];

  final List<Color> _surfaceLightPresets = const [
    Color(0xFFFFFFFF),
    Color(0xFFF0F0F2),
    Color(0xFFE5E9F0),
    Color(0xFFF2E5BC),
    Color(0xFFFFFFFF),
    Color(0xFFEEE8D5),
    Color(0xFFECECF0),
    Color(0xFFF1F6F9),
    Color(0xFFE6E9EF),
  ];

  final List<Color> _accentPresets = const [
    Color(0xFFFF5722), // Signal Orange
    Color(0xFFFFB000), // Amber Phosphor
    Color(0xFF00E676), // Radar Green
    Color(0xFF00B4D8), // Cyan
    Color(0xFF88C0D0), // Frost Teal
    Color(0xFFFF3B30), // Swiss Red
    Color(0xFFFABD2F), // Gruvbox Yellow
    Color(0xFF7AA2F7), // Tokyo Blue
    Color(0xFFFAB387), // Catppuccin Peach
    Color(0xFF2AA198), // Solarized Cyan
    Color(0xFFAEEA00), // Lime Green
    Color(0xFFE040FB), // Electric Violet
  ];

  @override
  void initState() {
    super.initState();
    final currentCustom = context.read<ThemeCubit>().state.customConfig;
    _isDark = currentCustom.isDark;
    _bgPrimary = currentCustom.bgPrimary;
    _bgSurface = currentCustom.bgSurface;
    _accentPrimary = currentCustom.accentPrimary;
    _accentSecondary = currentCustom.accentSecondary;
  }

  CustomThemeConfig get _currentConfig => CustomThemeConfig(
        bgPrimaryValue: _bgPrimary.toARGB32(),
        bgSurfaceValue: _bgSurface.toARGB32(),
        accentPrimaryValue: _accentPrimary.toARGB32(),
        accentSecondaryValue: _accentSecondary.toARGB32(),
        isDark: _isDark,
      );

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final previewColors = AppTheme.getColorsFor(
      AppThemeId.custom,
      isDark: _isDark,
      customConfig: _currentConfig,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Theme Studio'),
        actions: [
          TextButton(
            onPressed: _saveAndApply,
            child: const Text(
              'Save & Apply',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Live Custom Preview
          const Text(
            'LIVE CUSTOM PREVIEW',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          RepaintBoundary(
            child: _buildLivePreview(previewColors),
          ),
          const SizedBox(height: 24),

          // Base Tone Switch
          _buildToneSwitch(colors),
          const SizedBox(height: 20),

          // Primary Background
          _buildColorSection(
            title: 'PRIMARY BACKGROUND (BASE)',
            subtitle: 'Canvas layer for main screens and lists',
            selectedColor: _bgPrimary,
            presets: _isDark ? _bgDarkPresets : _bgLightPresets,
            onColorSelected: (c) => setState(() => _bgPrimary = c),
          ),
          const SizedBox(height: 20),

          // Surface / Card Color
          _buildColorSection(
            title: 'SURFACE & CARDS',
            subtitle: 'Panels, sheets, and widget containers',
            selectedColor: _bgSurface,
            presets: _isDark ? _surfaceDarkPresets : _surfaceLightPresets,
            onColorSelected: (c) => setState(() => _bgSurface = c),
          ),
          const SizedBox(height: 20),

          // Primary Accent
          _buildColorSection(
            title: 'PRIMARY ACCENT',
            subtitle: 'Buttons, active indicators, and hero highlights',
            selectedColor: _accentPrimary,
            presets: _accentPresets,
            onColorSelected: (c) => setState(() => _accentPrimary = c),
          ),
          const SizedBox(height: 20),

          // Secondary Accent
          _buildColorSection(
            title: 'SECONDARY ACCENT',
            subtitle: 'Telemetry badges, auxiliary stats, and tags',
            selectedColor: _accentSecondary,
            presets: _accentPresets,
            onColorSelected: (c) => setState(() => _accentSecondary = c),
          ),
          const SizedBox(height: 32),

          // Apply Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentPrimary,
                foregroundColor: _isDark ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _saveAndApply,
              child: const Text(
                'APPLY CUSTOM THEME',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.5),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _saveAndApply() {
    context.read<ThemeCubit>().updateCustomTheme(_currentConfig);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Custom Developer Theme saved & applied!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    context.pop();
  }

  Widget _buildLivePreview(AppThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgBase,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CUSTOM PALETTE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: colors.textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.accentPrimary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _isDark ? 'DARK MODE' : 'LIGHT MODE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: _isDark ? Colors.black : Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border(left: BorderSide(color: colors.accentPrimary, width: 3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SYSTEM MONITOR',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Process Watcher Active',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.check_circle_rounded, color: colors.accentPrimary, size: 20),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: colors.bgElevated,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.hub_rounded, size: 14, color: colors.accentSecondary),
                      const SizedBox(width: 6),
                      Text(
                        'Telemetry',
                        style: TextStyle(fontSize: 12, color: colors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: colors.bgElevated,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.bolt_rounded, size: 14, color: colors.accentPrimary),
                      const SizedBox(width: 6),
                      Text(
                        'Trigger',
                        style: TextStyle(fontSize: 12, color: colors.textPrimary),
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

  Widget _buildToneSwitch(AppThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isDark = true;
                  _bgPrimary = _bgDarkPresets.first;
                  _bgSurface = _surfaceDarkPresets.first;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _isDark ? colors.accentPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'Dark Palette',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _isDark
                          ? (context.isDarkMode ? Colors.black : Colors.white)
                          : colors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isDark = false;
                  _bgPrimary = _bgLightPresets.first;
                  _bgSurface = _surfaceLightPresets.first;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: !_isDark ? colors.accentPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'Light Palette',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: !_isDark
                          ? (context.isDarkMode ? Colors.black : Colors.white)
                          : colors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorSection({
    required String title,
    required String subtitle,
    required Color selectedColor,
    required List<Color> presets,
    required ValueChanged<Color> onColorSelected,
  }) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderSubtle, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: colors.textSecondary),
                  ),
                ],
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: selectedColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white30, width: 1.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: presets.map((color) {
              final isPicked = color.toARGB32() == selectedColor.toARGB32();
              return GestureDetector(
                onTap: () => onColorSelected(color),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isPicked ? colors.accentPrimary : Colors.white24,
                      width: isPicked ? 2.5 : 1,
                    ),
                  ),
                  child: isPicked
                      ? Icon(
                          Icons.check,
                          size: 16,
                          color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                        )
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
