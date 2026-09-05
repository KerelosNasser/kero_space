import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/custom_theme_config.dart';

enum AppThemeId {
  monochrome,
  gruvbox,
  amberCrt,
  nordic,
  milSpecHud,
  graphite,
  solarized,
  tokyoNight,
  draftingBlueprint,
  catppuccin,
  custom,
}

extension AppThemeIdDetails on AppThemeId {
  String get displayName {
    switch (this) {
      case AppThemeId.monochrome:
        return 'Monochrome Industrial';
      case AppThemeId.gruvbox:
        return 'Gruvbox Tactical';
      case AppThemeId.amberCrt:
        return 'Amber CRT Console';
      case AppThemeId.nordic:
        return 'Nordic Slate';
      case AppThemeId.milSpecHud:
        return 'Mil-Spec HUD';
      case AppThemeId.graphite:
        return 'Graphite Monolith';
      case AppThemeId.solarized:
        return 'Solarized Core';
      case AppThemeId.tokyoNight:
        return 'Tokyo Midnight';
      case AppThemeId.draftingBlueprint:
        return 'Drafting Blueprint';
      case AppThemeId.catppuccin:
        return 'Catppuccin Studio';
      case AppThemeId.custom:
        return 'Custom Developer Theme';
    }
  }

  String get tagline {
    switch (this) {
      case AppThemeId.monochrome:
        return 'Braun / Rams functionalism. Pure signal.';
      case AppThemeId.gruvbox:
        return 'Warm Unix hacker terminal. Zero eye fatigue.';
      case AppThemeId.amberCrt:
        return 'VT220 phosphor amber. Vintage mainframe power.';
      case AppThemeId.nordic:
        return 'Arctic IDE precision. Balanced syntax clarity.';
      case AppThemeId.milSpecHud:
        return 'Tactical telemetry radar. Hardware diagnostic unit.';
      case AppThemeId.graphite:
        return 'Swiss aerospace geometry. High-contrast discipline.';
      case AppThemeId.solarized:
        return 'Mathematically tuned scientific lab workstation.';
      case AppThemeId.tokyoNight:
        return 'Stealth modern terminal with laser accents.';
      case AppThemeId.draftingBlueprint:
        return 'CAD architectural drafting & schematics.';
      case AppThemeId.catppuccin:
        return 'Matte low-strain studio for deep focus sprints.';
      case AppThemeId.custom:
        return 'User-tailored developer palette & contrast.';
    }
  }

  String get tag {
    switch (this) {
      case AppThemeId.monochrome:
        return 'INDUSTRIAL';
      case AppThemeId.gruvbox:
        return 'RETRO UNIX';
      case AppThemeId.amberCrt:
        return 'TERMINAL';
      case AppThemeId.nordic:
        return 'ARCTIC';
      case AppThemeId.milSpecHud:
        return 'MIL-SPEC';
      case AppThemeId.graphite:
        return 'SWISS';
      case AppThemeId.solarized:
        return 'SCIENTIFIC';
      case AppThemeId.tokyoNight:
        return 'MIDNIGHT';
      case AppThemeId.draftingBlueprint:
        return 'SCHEMATIC';
      case AppThemeId.catppuccin:
        return 'STUDIO';
      case AppThemeId.custom:
        return 'CUSTOM';
    }
  }
}

class AppThemeColors extends ThemeExtension<AppThemeColors> {
  final Color bgBase;
  final Color bgSurface;
  final Color bgElevated;
  final Color bgOverlay;
  final Color borderSubtle;
  final Color divider;

  final Color textPrimary;
  final Color textSecondary;
  final Color textDisabled;

  final Color accentPrimary;
  final Color accentSecondary;
  final Color accentSuccess;
  final Color accentWarning;
  final Color accentError;

  final Color domainProductivity;
  final Color domainHealth;
  final Color domainFinance;
  final Color domainChurch;
  final Color domainTelemetry;

  const AppThemeColors({
    required this.bgBase,
    required this.bgSurface,
    required this.bgElevated,
    required this.bgOverlay,
    required this.borderSubtle,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDisabled,
    required this.accentPrimary,
    required this.accentSecondary,
    required this.accentSuccess,
    required this.accentWarning,
    required this.accentError,
    required this.domainProductivity,
    required this.domainHealth,
    required this.domainFinance,
    required this.domainChurch,
    required this.domainTelemetry,
  });

  @override
  AppThemeColors copyWith({
    Color? bgBase,
    Color? bgSurface,
    Color? bgElevated,
    Color? bgOverlay,
    Color? borderSubtle,
    Color? divider,
    Color? textPrimary,
    Color? textSecondary,
    Color? textDisabled,
    Color? accentPrimary,
    Color? accentSecondary,
    Color? accentSuccess,
    Color? accentWarning,
    Color? accentError,
    Color? domainProductivity,
    Color? domainHealth,
    Color? domainFinance,
    Color? domainChurch,
    Color? domainTelemetry,
  }) {
    return AppThemeColors(
      bgBase: bgBase ?? this.bgBase,
      bgSurface: bgSurface ?? this.bgSurface,
      bgElevated: bgElevated ?? this.bgElevated,
      bgOverlay: bgOverlay ?? this.bgOverlay,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      divider: divider ?? this.divider,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textDisabled: textDisabled ?? this.textDisabled,
      accentPrimary: accentPrimary ?? this.accentPrimary,
      accentSecondary: accentSecondary ?? this.accentSecondary,
      accentSuccess: accentSuccess ?? this.accentSuccess,
      accentWarning: accentWarning ?? this.accentWarning,
      accentError: accentError ?? this.accentError,
      domainProductivity: domainProductivity ?? this.domainProductivity,
      domainHealth: domainHealth ?? this.domainHealth,
      domainFinance: domainFinance ?? this.domainFinance,
      domainChurch: domainChurch ?? this.domainChurch,
      domainTelemetry: domainTelemetry ?? this.domainTelemetry,
    );
  }

  @override
  AppThemeColors lerp(ThemeExtension<AppThemeColors>? other, double t) {
    if (other is! AppThemeColors) return this;
    return AppThemeColors(
      bgBase: Color.lerp(bgBase, other.bgBase, t) ?? bgBase,
      bgSurface: Color.lerp(bgSurface, other.bgSurface, t) ?? bgSurface,
      bgElevated: Color.lerp(bgElevated, other.bgElevated, t) ?? bgElevated,
      bgOverlay: Color.lerp(bgOverlay, other.bgOverlay, t) ?? bgOverlay,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t) ?? borderSubtle,
      divider: Color.lerp(divider, other.divider, t) ?? divider,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t) ?? textPrimary,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t) ?? textSecondary,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t) ?? textDisabled,
      accentPrimary: Color.lerp(accentPrimary, other.accentPrimary, t) ?? accentPrimary,
      accentSecondary: Color.lerp(accentSecondary, other.accentSecondary, t) ?? accentSecondary,
      accentSuccess: Color.lerp(accentSuccess, other.accentSuccess, t) ?? accentSuccess,
      accentWarning: Color.lerp(accentWarning, other.accentWarning, t) ?? accentWarning,
      accentError: Color.lerp(accentError, other.accentError, t) ?? accentError,
      domainProductivity: Color.lerp(domainProductivity, other.domainProductivity, t) ?? domainProductivity,
      domainHealth: Color.lerp(domainHealth, other.domainHealth, t) ?? domainHealth,
      domainFinance: Color.lerp(domainFinance, other.domainFinance, t) ?? domainFinance,
      domainChurch: Color.lerp(domainChurch, other.domainChurch, t) ?? domainChurch,
      domainTelemetry: Color.lerp(domainTelemetry, other.domainTelemetry, t) ?? domainTelemetry,
    );
  }
}

extension AppThemeContext on BuildContext {
  AppThemeColors get appColors =>
      Theme.of(this).extension<AppThemeColors>() ?? AppTheme.defaultDarkColors;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}

class AppTheme {
  // Backward compatibility static getters
  static const Color bgPrimary = Color(0xFF0A0A0C);
  static const Color bgBase = Color(0xFF0A0A0C);
  static const Color bgSurface = Color(0xFF141416);
  static const Color bgElevated = Color(0xFF202024);
  static const Color bgOverlay = Color(0x99000000);
  static const Color divider = Color(0xFF2A2A30);

  static const Color accentPrimary = Color(0xFFFF5722);
  static const Color accentCyan = Color(0xFF00B4D8);
  static const Color accentMint = Color(0xFF00E676);
  static const Color accentRose = Color(0xFFFF453A);
  static const Color accentGold = Color(0xFFFFB000);
  static const Color accentViolet = Color(0xFF88C0D0);

  static const Color textPrimary = Color(0xFFF2F2F2);
  static const Color textSecondary = Color(0x99EBEBF5);
  static const Color textDisabled = Color(0x4DEBEBF5);

  static final Map<String, ThemeData> _themeCache = {};

  static ThemeData get darkTheme => getThemeData(AppThemeId.monochrome, isDark: true);
  static ThemeData get lightTheme => getThemeData(AppThemeId.monochrome, isDark: false);

  static ThemeData getThemeData(
    AppThemeId id, {
    required bool isDark,
    CustomThemeConfig? customConfig,
  }) {
    final cacheKey = '${id.name}_${isDark ? "dark" : "light"}_${id == AppThemeId.custom ? customConfig?.hashCode : ""}';
    if (_themeCache.containsKey(cacheKey)) {
      return _themeCache[cacheKey]!;
    }

    final colors = _resolveColors(id, isDark: isDark, customConfig: customConfig);
    final themeData = _buildThemeData(colors, isDark: isDark);
    _themeCache[cacheKey] = themeData;
    return themeData;
  }

  static AppThemeColors getColorsFor(
    AppThemeId id, {
    required bool isDark,
    CustomThemeConfig? customConfig,
  }) {
    return _resolveColors(id, isDark: isDark, customConfig: customConfig);
  }

  static ThemeData _buildThemeData(AppThemeColors colors, {required bool isDark}) {
    final brightness = isDark ? Brightness.dark : Brightness.light;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: colors.bgBase,
      primaryColor: colors.accentPrimary,
      fontFamily: 'SF Pro Text',
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: colors.accentPrimary,
        onPrimary: isDark ? Colors.black : Colors.white,
        secondary: colors.accentSecondary,
        onSecondary: isDark ? Colors.black : Colors.white,
        error: colors.accentError,
        onError: Colors.white,
        surface: colors.bgSurface,
        onSurface: colors.textPrimary,
      ),
      extensions: [colors],
      cardTheme: CardThemeData(
        color: colors.bgSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colors.borderSubtle, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.bgBase,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: colors.textPrimary,
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.bgBase,
        elevation: 0,
        selectedItemColor: colors.accentPrimary,
        unselectedItemColor: colors.textDisabled,
        selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colors.bgBase,
        elevation: 0,
        selectedIconTheme: IconThemeData(color: colors.accentPrimary),
        unselectedIconTheme: IconThemeData(color: colors.textDisabled),
        selectedLabelTextStyle: TextStyle(color: colors.accentPrimary, fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelTextStyle: TextStyle(color: colors.textDisabled, fontSize: 11, fontWeight: FontWeight.w500),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.accentPrimary,
        foregroundColor: isDark ? Colors.black : Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colors.accentPrimary;
          return colors.textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.accentPrimary.withValues(alpha: 0.35);
          }
          return colors.bgElevated;
        }),
      ),
      dividerTheme: DividerThemeData(
        color: colors.divider,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.bgSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.borderSubtle, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.borderSubtle, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.accentPrimary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hintStyle: TextStyle(color: colors.textDisabled),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.accentPrimary,
          foregroundColor: isDark ? Colors.black : Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.textPrimary,
          side: BorderSide(color: colors.borderSubtle, width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
    );
  }

  static AppThemeColors _resolveColors(
    AppThemeId id, {
    required bool isDark,
    CustomThemeConfig? customConfig,
  }) {
    switch (id) {
      case AppThemeId.monochrome:
        return isDark ? defaultDarkColors : _monochromeLight;
      case AppThemeId.gruvbox:
        return isDark ? _gruvboxDark : _gruvboxLight;
      case AppThemeId.amberCrt:
        return isDark ? _amberCrtDark : _amberCrtLight;
      case AppThemeId.nordic:
        return isDark ? _nordicDark : _nordicLight;
      case AppThemeId.milSpecHud:
        return isDark ? _milSpecDark : _milSpecLight;
      case AppThemeId.graphite:
        return isDark ? _graphiteDark : _graphiteLight;
      case AppThemeId.solarized:
        return isDark ? _solarizedDark : _solarizedLight;
      case AppThemeId.tokyoNight:
        return isDark ? _tokyoNightDark : _tokyoNightLight;
      case AppThemeId.draftingBlueprint:
        return isDark ? _blueprintDark : _blueprintLight;
      case AppThemeId.catppuccin:
        return isDark ? _catppuccinDark : _catppuccinLight;
      case AppThemeId.custom:
        final cfg = customConfig ?? (isDark ? CustomThemeConfig.defaultDark : CustomThemeConfig.defaultLight);
        return _buildFromCustom(cfg, isDark: isDark);
    }
  }

  // 1. Monochrome Industrial (Braun / Rams)
  static const defaultDarkColors = AppThemeColors(
    bgBase: Color(0xFF0A0A0C),
    bgSurface: Color(0xFF141417),
    bgElevated: Color(0xFF1E1E23),
    bgOverlay: Color(0xCC000000),
    borderSubtle: Color(0xFF26262D),
    divider: Color(0xFF1F1F24),
    textPrimary: Color(0xFFEDEDED),
    textSecondary: Color(0xFFA0A0A8),
    textDisabled: Color(0xFF55555D),
    accentPrimary: Color(0xFFFF5722), // Signal Orange
    accentSecondary: Color(0xFFDCDCDA),
    accentSuccess: Color(0xFF388E3C),
    accentWarning: Color(0xFFFFA000),
    accentError: Color(0xFFD32F2F),
    domainProductivity: Color(0xFFFF5722),
    domainHealth: Color(0xFF4CAF50),
    domainFinance: Color(0xFFFFB300),
    domainChurch: Color(0xFFB0BEC5),
    domainTelemetry: Color(0xFF90A4AE),
  );

  static const _monochromeLight = AppThemeColors(
    bgBase: Color(0xFFF3F3F1),
    bgSurface: Color(0xFFFFFFFF),
    bgElevated: Color(0xFFE8E8E4),
    bgOverlay: Color(0x66000000),
    borderSubtle: Color(0xFFD4D4CE),
    divider: Color(0xFFDFDFD9),
    textPrimary: Color(0xFF1C1C1E),
    textSecondary: Color(0xFF5F5F67),
    textDisabled: Color(0xFFA2A2A8),
    accentPrimary: Color(0xFFD84315),
    accentSecondary: Color(0xFF2E2E32),
    accentSuccess: Color(0xFF2E7D32),
    accentWarning: Color(0xFFED6C02),
    accentError: Color(0xFFC62828),
    domainProductivity: Color(0xFFD84315),
    domainHealth: Color(0xFF2E7D32),
    domainFinance: Color(0xFFE65100),
    domainChurch: Color(0xFF455A64),
    domainTelemetry: Color(0xFF37474F),
  );

  // 2. Gruvbox Tactical
  static const _gruvboxDark = AppThemeColors(
    bgBase: Color(0xFF1D2021),
    bgSurface: Color(0xFF282828),
    bgElevated: Color(0xFF3C3836),
    bgOverlay: Color(0xCC000000),
    borderSubtle: Color(0xFF504945),
    divider: Color(0xFF32302F),
    textPrimary: Color(0xFFEBDBB2),
    textSecondary: Color(0xFFA89984),
    textDisabled: Color(0xFF665C54),
    accentPrimary: Color(0xFFFABD2F), // Gruvbox Yellow
    accentSecondary: Color(0xFF83A598), // Gruvbox Blue
    accentSuccess: Color(0xFFB8BB26), // Sage
    accentWarning: Color(0xFFFE8019), // Orange
    accentError: Color(0xFFFB4934), // Red
    domainProductivity: Color(0xFFFABD2F),
    domainHealth: Color(0xFFB8BB26),
    domainFinance: Color(0xFFFE8019),
    domainChurch: Color(0xFFD3869B),
    domainTelemetry: Color(0xFF83A598),
  );

  static const _gruvboxLight = AppThemeColors(
    bgBase: Color(0xFFFBF1C7),
    bgSurface: Color(0xFFF2E5BC),
    bgElevated: Color(0xFFEBDBB2),
    bgOverlay: Color(0x66000000),
    borderSubtle: Color(0xFFD5C4A1),
    divider: Color(0xFFE0D3AF),
    textPrimary: Color(0xFF282828),
    textSecondary: Color(0xFF7C6F64),
    textDisabled: Color(0xFFA89984),
    accentPrimary: Color(0xFFB57614),
    accentSecondary: Color(0xFF076678),
    accentSuccess: Color(0xFF79740E),
    accentWarning: Color(0xFFAF3A03),
    accentError: Color(0xFF9D0006),
    domainProductivity: Color(0xFFB57614),
    domainHealth: Color(0xFF79740E),
    domainFinance: Color(0xFFAF3A03),
    domainChurch: Color(0xFF8F3F71),
    domainTelemetry: Color(0xFF076678),
  );

  // 3. Amber CRT Console
  static const _amberCrtDark = AppThemeColors(
    bgBase: Color(0xFF080A08),
    bgSurface: Color(0xFF111411),
    bgElevated: Color(0xFF1B201B),
    bgOverlay: Color(0xDD000000),
    borderSubtle: Color(0xFF2B332B),
    divider: Color(0xFF1E261E),
    textPrimary: Color(0xFFFFB000), // Phosphor
    textSecondary: Color(0xFFB37B00),
    textDisabled: Color(0xFF664600),
    accentPrimary: Color(0xFFFFB000),
    accentSecondary: Color(0xFFFFC84A),
    accentSuccess: Color(0xFF88FF00),
    accentWarning: Color(0xFFFF8800),
    accentError: Color(0xFFFF3300),
    domainProductivity: Color(0xFFFFB000),
    domainHealth: Color(0xFF88FF00),
    domainFinance: Color(0xFFFF9400),
    domainChurch: Color(0xFFFFD54F),
    domainTelemetry: Color(0xFFFFB000),
  );

  static const _amberCrtLight = AppThemeColors(
    bgBase: Color(0xFFFBF6EC),
    bgSurface: Color(0xFFF2E7D0),
    bgElevated: Color(0xFFE4D5B7),
    bgOverlay: Color(0x66000000),
    borderSubtle: Color(0xFFCFBF9E),
    divider: Color(0xFFDCCDB0),
    textPrimary: Color(0xFF4A3400),
    textSecondary: Color(0xFF7D5900),
    textDisabled: Color(0xFFA67A08),
    accentPrimary: Color(0xFFB26F00),
    accentSecondary: Color(0xFF7E4A00),
    accentSuccess: Color(0xFF4D8000),
    accentWarning: Color(0xFFB35900),
    accentError: Color(0xFFA81D00),
    domainProductivity: Color(0xFFB26F00),
    domainHealth: Color(0xFF4D8000),
    domainFinance: Color(0xFF9E4B00),
    domainChurch: Color(0xFF734D00),
    domainTelemetry: Color(0xFFB26F00),
  );

  // 4. Nordic Slate
  static const _nordicDark = AppThemeColors(
    bgBase: Color(0xFF14171C),
    bgSurface: Color(0xFF1C2128),
    bgElevated: Color(0xFF262C36),
    bgOverlay: Color(0xCC000000),
    borderSubtle: Color(0xFF333B4A),
    divider: Color(0xFF242A35),
    textPrimary: Color(0xFFECEFF4),
    textSecondary: Color(0xFF9BA4B5),
    textDisabled: Color(0xFF5A6375),
    accentPrimary: Color(0xFF88C0D0), // Frost Teal
    accentSecondary: Color(0xFF81A1C1),
    accentSuccess: Color(0xFFA3BE8C),
    accentWarning: Color(0xFFEBCB8B),
    accentError: Color(0xFFBF616A),
    domainProductivity: Color(0xFF88C0D0),
    domainHealth: Color(0xFFA3BE8C),
    domainFinance: Color(0xFFEBCB8B),
    domainChurch: Color(0xFFB48EAD),
    domainTelemetry: Color(0xFF81A1C1),
  );

  static const _nordicLight = AppThemeColors(
    bgBase: Color(0xFFECEFF4),
    bgSurface: Color(0xFFE5E9F0),
    bgElevated: Color(0xFFD8DEE9),
    bgOverlay: Color(0x66000000),
    borderSubtle: Color(0xFFC4CBD8),
    divider: Color(0xFFCCD4E2),
    textPrimary: Color(0xFF2E3440),
    textSecondary: Color(0xFF4C566A),
    textDisabled: Color(0xFF95A0B5),
    accentPrimary: Color(0xFF3B6E8C),
    accentSecondary: Color(0xFF4B6B94),
    accentSuccess: Color(0xFF5E824A),
    accentWarning: Color(0xFF9E7E36),
    accentError: Color(0xFF993E46),
    domainProductivity: Color(0xFF3B6E8C),
    domainHealth: Color(0xFF5E824A),
    domainFinance: Color(0xFF9E7E36),
    domainChurch: Color(0xFF7A5173),
    domainTelemetry: Color(0xFF4B6B94),
  );

  // 5. Mil-Spec HUD
  static const _milSpecDark = AppThemeColors(
    bgBase: Color(0xFF0A0D0B),
    bgSurface: Color(0xFF131A14),
    bgElevated: Color(0xFF1C261E),
    bgOverlay: Color(0xDD000000),
    borderSubtle: Color(0xFF27382B),
    divider: Color(0xFF1C291F),
    textPrimary: Color(0xFFE1E8E2),
    textSecondary: Color(0xFF889C8C),
    textDisabled: Color(0xFF495E4D),
    accentPrimary: Color(0xFF00E676), // Radar Green
    accentSecondary: Color(0xFFAEEA00),
    accentSuccess: Color(0xFF00E676),
    accentWarning: Color(0xFFFFD600),
    accentError: Color(0xFFFF1744),
    domainProductivity: Color(0xFF00E676),
    domainHealth: Color(0xFFAEEA00),
    domainFinance: Color(0xFFFFD600),
    domainChurch: Color(0xFF69F0AE),
    domainTelemetry: Color(0xFF00E676),
  );

  static const _milSpecLight = AppThemeColors(
    bgBase: Color(0xFFEEF3EF),
    bgSurface: Color(0xFFE2EBE4),
    bgElevated: Color(0xFFD1DFD4),
    bgOverlay: Color(0x66000000),
    borderSubtle: Color(0xFFB5C7B9),
    divider: Color(0xFFC3D4C7),
    textPrimary: Color(0xFF18241B),
    textSecondary: Color(0xFF4A624F),
    textDisabled: Color(0xFF879E8C),
    accentPrimary: Color(0xFF008A44),
    accentSecondary: Color(0xFF6B8F00),
    accentSuccess: Color(0xFF008A44),
    accentWarning: Color(0xFF997A00),
    accentError: Color(0xFFA80022),
    domainProductivity: Color(0xFF008A44),
    domainHealth: Color(0xFF6B8F00),
    domainFinance: Color(0xFF997A00),
    domainChurch: Color(0xFF2D7D54),
    domainTelemetry: Color(0xFF008A44),
  );

  // 6. Graphite Monolith
  static const _graphiteDark = AppThemeColors(
    bgBase: Color(0xFF000000),
    bgSurface: Color(0xFF111111),
    bgElevated: Color(0xFF1E1E1E),
    bgOverlay: Color(0xEE000000),
    borderSubtle: Color(0xFF2A2A2A),
    divider: Color(0xFF1C1C1C),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFF888888),
    textDisabled: Color(0xFF444444),
    accentPrimary: Color(0xFFFF3B30), // Swiss Red
    accentSecondary: Color(0xFFE5E5EA),
    accentSuccess: Color(0xFF34C759),
    accentWarning: Color(0xFFFF9500),
    accentError: Color(0xFFFF3B30),
    domainProductivity: Color(0xFFFF3B30),
    domainHealth: Color(0xFF34C759),
    domainFinance: Color(0xFFFF9500),
    domainChurch: Color(0xFFAF52DE),
    domainTelemetry: Color(0xFFE5E5EA),
  );

  static const _graphiteLight = AppThemeColors(
    bgBase: Color(0xFFFAFAFA),
    bgSurface: Color(0xFFFFFFFF),
    bgElevated: Color(0xFFEFEFEF),
    bgOverlay: Color(0x66000000),
    borderSubtle: Color(0xFFDFDFDF),
    divider: Color(0xFFE5E5E5),
    textPrimary: Color(0xFF000000),
    textSecondary: Color(0xFF666666),
    textDisabled: Color(0xFFAAAAAA),
    accentPrimary: Color(0xFFD70015),
    accentSecondary: Color(0xFF2C2C2E),
    accentSuccess: Color(0xFF248A3D),
    accentWarning: Color(0xFFC97800),
    accentError: Color(0xFFD70015),
    domainProductivity: Color(0xFFD70015),
    domainHealth: Color(0xFF248A3D),
    domainFinance: Color(0xFFC97800),
    domainChurch: Color(0xFF8944AB),
    domainTelemetry: Color(0xFF2C2C2E),
  );

  // 7. Solarized Core
  static const _solarizedDark = AppThemeColors(
    bgBase: Color(0xFF00212B),
    bgSurface: Color(0xFF073642),
    bgElevated: Color(0xFF0D4857),
    bgOverlay: Color(0xCC000000),
    borderSubtle: Color(0xFF145869),
    divider: Color(0xFF0B3E4C),
    textPrimary: Color(0xFF93A1A1),
    textSecondary: Color(0xFF657B83),
    textDisabled: Color(0xFF586E75),
    accentPrimary: Color(0xFF2AA198), // Cyan
    accentSecondary: Color(0xFF268BD2), // Blue
    accentSuccess: Color(0xFF859900), // Green
    accentWarning: Color(0xFFB58900), // Yellow
    accentError: Color(0xFFDC322F), // Red
    domainProductivity: Color(0xFF2AA198),
    domainHealth: Color(0xFF859900),
    domainFinance: Color(0xFFB58900),
    domainChurch: Color(0xFF6C71C4),
    domainTelemetry: Color(0xFF268BD2),
  );

  static const _solarizedLight = AppThemeColors(
    bgBase: Color(0xFFFDF6E3),
    bgSurface: Color(0xFFEEE8D5),
    bgElevated: Color(0xFFDFD7BE),
    bgOverlay: Color(0x66000000),
    borderSubtle: Color(0xFFCCC0A2),
    divider: Color(0xFFDDD2B4),
    textPrimary: Color(0xFF073642),
    textSecondary: Color(0xFF586E75),
    textDisabled: Color(0xFF839496),
    accentPrimary: Color(0xFF268BD2),
    accentSecondary: Color(0xFF2AA198),
    accentSuccess: Color(0xFF718200),
    accentWarning: Color(0xFF997300),
    accentError: Color(0xFFBD2623),
    domainProductivity: Color(0xFF268BD2),
    domainHealth: Color(0xFF718200),
    domainFinance: Color(0xFF997300),
    domainChurch: Color(0xFF595EB0),
    domainTelemetry: Color(0xFF2AA198),
  );

  // 8. Tokyo Midnight
  static const _tokyoNightDark = AppThemeColors(
    bgBase: Color(0xFF101017),
    bgSurface: Color(0xFF161622),
    bgElevated: Color(0xFF212133),
    bgOverlay: Color(0xCC000000),
    borderSubtle: Color(0xFF2E2E46),
    divider: Color(0xFF1C1C2A),
    textPrimary: Color(0xFFC0CAF5),
    textSecondary: Color(0xFF7982A9),
    textDisabled: Color(0xFF4E5472),
    accentPrimary: Color(0xFF7AA2F7), // Tokyo Blue
    accentSecondary: Color(0xFF7DCFFF), // Cyan
    accentSuccess: Color(0xFF73DACA), // Green
    accentWarning: Color(0xFFE0AF68), // Orange
    accentError: Color(0xFFF7768E), // Crimson
    domainProductivity: Color(0xFF7AA2F7),
    domainHealth: Color(0xFF73DACA),
    domainFinance: Color(0xFFE0AF68),
    domainChurch: Color(0xFFBB9AF7),
    domainTelemetry: Color(0xFF7DCFFF),
  );

  static const _tokyoNightLight = AppThemeColors(
    bgBase: Color(0xFFE1E2E7),
    bgSurface: Color(0xFFECECF0),
    bgElevated: Color(0xFFD6D7DF),
    bgOverlay: Color(0x66000000),
    borderSubtle: Color(0xFFC2C4CF),
    divider: Color(0xFFCBCCD6),
    textPrimary: Color(0xFF343B58),
    textSecondary: Color(0xFF565F89),
    textDisabled: Color(0xFF8C93B3),
    accentPrimary: Color(0xFF2E7DE9),
    accentSecondary: Color(0xFF007197),
    accentSuccess: Color(0xFF38917A),
    accentWarning: Color(0xFF8F5E15),
    accentError: Color(0xFFB1394B),
    domainProductivity: Color(0xFF2E7DE9),
    domainHealth: Color(0xFF38917A),
    domainFinance: Color(0xFF8F5E15),
    domainChurch: Color(0xFF6B47B8),
    domainTelemetry: Color(0xFF007197),
  );

  // 9. Drafting Blueprint
  static const _blueprintDark = AppThemeColors(
    bgBase: Color(0xFF08121E),
    bgSurface: Color(0xFF0F2034),
    bgElevated: Color(0xFF172D49),
    bgOverlay: Color(0xCC000000),
    borderSubtle: Color(0xFF20426B),
    divider: Color(0xFF152A42),
    textPrimary: Color(0xFFE3F2FD),
    textSecondary: Color(0xFF82A7CA),
    textDisabled: Color(0xFF47698A),
    accentPrimary: Color(0xFF00B4D8), // Blueprint Cyan
    accentSecondary: Color(0xFF90E0EF),
    accentSuccess: Color(0xFF52B788),
    accentWarning: Color(0xFFFFB703),
    accentError: Color(0xFFE63946),
    domainProductivity: Color(0xFF00B4D8),
    domainHealth: Color(0xFF52B788),
    domainFinance: Color(0xFFFFB703),
    domainChurch: Color(0xFFB5E2FA),
    domainTelemetry: Color(0xFF00B4D8),
  );

  static const _blueprintLight = AppThemeColors(
    bgBase: Color(0xFFE8F1F5),
    bgSurface: Color(0xFFF1F6F9),
    bgElevated: Color(0xFFD6E4EB),
    bgOverlay: Color(0x66000000),
    borderSubtle: Color(0xFFB6CED9),
    divider: Color(0xFFC3D8E2),
    textPrimary: Color(0xFF0C2436),
    textSecondary: Color(0xFF3A5F79),
    textDisabled: Color(0xFF7A9CAB),
    accentPrimary: Color(0xFF0077B6),
    accentSecondary: Color(0xFF0096C7),
    accentSuccess: Color(0xFF368A62),
    accentWarning: Color(0xFFB37D00),
    accentError: Color(0xFFA8232D),
    domainProductivity: Color(0xFF0077B6),
    domainHealth: Color(0xFF368A62),
    domainFinance: Color(0xFFB37D00),
    domainChurch: Color(0xFF286488),
    domainTelemetry: Color(0xFF0096C7),
  );

  // 10. Catppuccin Studio
  static const _catppuccinDark = AppThemeColors(
    bgBase: Color(0xFF181825),
    bgSurface: Color(0xFF1E1E2E),
    bgElevated: Color(0xFF28283D),
    bgOverlay: Color(0xCC000000),
    borderSubtle: Color(0xFF3A3A54),
    divider: Color(0xFF252538),
    textPrimary: Color(0xFFCDD6F4),
    textSecondary: Color(0xFF9399B2),
    textDisabled: Color(0xFF585B70),
    accentPrimary: Color(0xFFFAB387), // Peach
    accentSecondary: Color(0xFF89DCEB), // Sky
    accentSuccess: Color(0xFFA6E3A1), // Green
    accentWarning: Color(0xFFF9E2AF), // Yellow
    accentError: Color(0xFFF38BA8), // Red
    domainProductivity: Color(0xFFFAB387),
    domainHealth: Color(0xFFA6E3A1),
    domainFinance: Color(0xFFF9E2AF),
    domainChurch: Color(0xFFCBA6F7),
    domainTelemetry: Color(0xFF89DCEB),
  );

  static const _catppuccinLight = AppThemeColors(
    bgBase: Color(0xFFEFF1F5),
    bgSurface: Color(0xFFE6E9EF),
    bgElevated: Color(0xFFCCD0DA),
    bgOverlay: Color(0x66000000),
    borderSubtle: Color(0xFFB8BFD0),
    divider: Color(0xFFC3CAD9),
    textPrimary: Color(0xFF4C4F69),
    textSecondary: Color(0xFF6C6F85),
    textDisabled: Color(0xFF9CA0B0),
    accentPrimary: Color(0xFFDD7878),
    accentSecondary: Color(0xFF1E66F5),
    accentSuccess: Color(0xFF40A02B),
    accentWarning: Color(0xFFDF8E1D),
    accentError: Color(0xFFD20F39),
    domainProductivity: Color(0xFFDD7878),
    domainHealth: Color(0xFF40A02B),
    domainFinance: Color(0xFFDF8E1D),
    domainChurch: Color(0xFF8839EF),
    domainTelemetry: Color(0xFF1E66F5),
  );

  static AppThemeColors _buildFromCustom(CustomThemeConfig cfg, {required bool isDark}) {
    final base = cfg.bgPrimary;
    final surface = cfg.bgSurface;
    final primary = cfg.accentPrimary;
    final secondary = cfg.accentSecondary;

    final elevated = isDark
        ? Color.alphaBlend(Colors.white.withValues(alpha: 0.06), surface)
        : Color.alphaBlend(Colors.black.withValues(alpha: 0.04), surface);

    final border = isDark
        ? Color.alphaBlend(Colors.white.withValues(alpha: 0.12), surface)
        : Color.alphaBlend(Colors.black.withValues(alpha: 0.10), surface);

    final divider = isDark
        ? Color.alphaBlend(Colors.white.withValues(alpha: 0.07), surface)
        : Color.alphaBlend(Colors.black.withValues(alpha: 0.06), surface);

    return AppThemeColors(
      bgBase: base,
      bgSurface: surface,
      bgElevated: elevated,
      bgOverlay: isDark ? const Color(0xCC000000) : const Color(0x66000000),
      borderSubtle: border,
      divider: divider,
      textPrimary: isDark ? const Color(0xFFEEEEEE) : const Color(0xFF1F1F1F),
      textSecondary: isDark ? const Color(0xFFAAAAAA) : const Color(0xFF666666),
      textDisabled: isDark ? const Color(0xFF555555) : const Color(0xFFAAAAAA),
      accentPrimary: primary,
      accentSecondary: secondary,
      accentSuccess: isDark ? const Color(0xFF4CAF50) : const Color(0xFF2E7D32),
      accentWarning: isDark ? const Color(0xFFFFB300) : const Color(0xFFE65100),
      accentError: isDark ? const Color(0xFFFF5252) : const Color(0xFFD32F2F),
      domainProductivity: primary,
      domainHealth: isDark ? const Color(0xFF4CAF50) : const Color(0xFF2E7D32),
      domainFinance: isDark ? const Color(0xFFFFB300) : const Color(0xFFE65100),
      domainChurch: secondary,
      domainTelemetry: primary,
    );
  }
}
