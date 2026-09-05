import 'package:flutter/material.dart';

class CustomThemeConfig {
  final int bgPrimaryValue;
  final int bgSurfaceValue;
  final int accentPrimaryValue;
  final int accentSecondaryValue;
  final bool isDark;

  const CustomThemeConfig({
    required this.bgPrimaryValue,
    required this.bgSurfaceValue,
    required this.accentPrimaryValue,
    required this.accentSecondaryValue,
    required this.isDark,
  });

  Color get bgPrimary => Color(bgPrimaryValue);
  Color get bgSurface => Color(bgSurfaceValue);
  Color get accentPrimary => Color(accentPrimaryValue);
  Color get accentSecondary => Color(accentSecondaryValue);

  static const defaultDark = CustomThemeConfig(
    bgPrimaryValue: 0xFF121214,
    bgSurfaceValue: 0xFF1B1B1F,
    accentPrimaryValue: 0xFFFF5722,
    accentSecondaryValue: 0xFF00E5FF,
    isDark: true,
  );

  static const defaultLight = CustomThemeConfig(
    bgPrimaryValue: 0xFFF5F5F7,
    bgSurfaceValue: 0xFFFFFFFF,
    accentPrimaryValue: 0xFFE65100,
    accentSecondaryValue: 0xFF0097A7,
    isDark: false,
  );

  CustomThemeConfig copyWith({
    int? bgPrimaryValue,
    int? bgSurfaceValue,
    int? accentPrimaryValue,
    int? accentSecondaryValue,
    bool? isDark,
  }) {
    return CustomThemeConfig(
      bgPrimaryValue: bgPrimaryValue ?? this.bgPrimaryValue,
      bgSurfaceValue: bgSurfaceValue ?? this.bgSurfaceValue,
      accentPrimaryValue: accentPrimaryValue ?? this.accentPrimaryValue,
      accentSecondaryValue: accentSecondaryValue ?? this.accentSecondaryValue,
      isDark: isDark ?? this.isDark,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bgPrimaryValue': bgPrimaryValue,
      'bgSurfaceValue': bgSurfaceValue,
      'accentPrimaryValue': accentPrimaryValue,
      'accentSecondaryValue': accentSecondaryValue,
      'isDark': isDark,
    };
  }

  factory CustomThemeConfig.fromJson(Map<String, dynamic> json) {
    return CustomThemeConfig(
      bgPrimaryValue: json['bgPrimaryValue'] as int? ?? 0xFF121214,
      bgSurfaceValue: json['bgSurfaceValue'] as int? ?? 0xFF1B1B1F,
      accentPrimaryValue: json['accentPrimaryValue'] as int? ?? 0xFFFF5722,
      accentSecondaryValue: json['accentSecondaryValue'] as int? ?? 0xFF00E5FF,
      isDark: json['isDark'] as bool? ?? true,
    );
  }
}
