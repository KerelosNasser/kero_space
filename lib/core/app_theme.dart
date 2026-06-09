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
    );
  }
}
