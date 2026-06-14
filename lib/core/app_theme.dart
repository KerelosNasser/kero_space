import 'package:flutter/material.dart';

class AppTheme {
  static const Color bgPrimary = Color(0xFF000000);
  static const Color bgSurface = Color(0xFF1C1C1E);
  static const Color bgElevated = Color(0xFF2C2C2E);
  static const Color bgOverlay = Color(0x99000000);

  static const Color accentPrimary = Color(0xFFFFFFFF);
  static const Color accentCyan = Color(0xFF0A84FF);
  static const Color accentMint = Color(0xFF32D74B);
  static const Color accentRose = Color(0xFFFF453A);
  static const Color accentGold = Color(0xFFFF9F0A);
  static const Color accentViolet = Color(0xFFBF5AF2);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0x99EBEBF5);
  static const Color textDisabled = Color(0x4DEBEBF5);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgPrimary,
      primaryColor: accentPrimary,
      fontFamily: 'SF Pro Text',
      colorScheme: const ColorScheme.dark(
        primary: accentPrimary,
        secondary: accentCyan,
        surface: bgSurface,
        error: accentRose,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: textPrimary),
        titleLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: textPrimary),
        titleMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: textPrimary),
        headlineMedium: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: textPrimary),
        bodyLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w400, color: textPrimary),
        labelSmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: bgSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bgPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: textPrimary),
        iconTheme: IconThemeData(color: accentPrimary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: bgPrimary,
        elevation: 0,
        selectedItemColor: accentPrimary,
        unselectedItemColor: textDisabled,
        showSelectedLabels: false,
        showUnselectedLabels: false,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentPrimary,
        foregroundColor: bgPrimary,
        elevation: 4,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accentPrimary;
          return textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accentViolet;
          return bgElevated;
        }),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: accentPrimary,
        unselectedLabelColor: textSecondary,
        indicatorColor: accentPrimary,
        indicatorSize: TabBarIndicatorSize.tab,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentCyan, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF38383A),
        thickness: 1,
        space: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentCyan,
          foregroundColor: accentPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
