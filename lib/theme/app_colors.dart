import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kinsenas Earthy Botanical Design System
/// Supports both Dark Mode and Light Mode while preserving the signature
/// Earthy Botanical palette:
/// - White Smoke (#EFF1ED)
/// - Dark Khaki (#373D20)
/// - Dusty Olive (#717744)
/// - Dry Sage (#BCBD8B)
/// - Ash Brown (#766153)
class AppColors {
  static const String _prefKeyDarkMode = 'is_dark_mode';

  /// Global theme notifier for reactive Dark / Light mode switching
  static final ValueNotifier<ThemeMode> themeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.dark);

  static bool get isDark => themeNotifier.value != ThemeMode.light;

  static Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkPref = prefs.getBool(_prefKeyDarkMode) ?? true;
    themeNotifier.value = isDarkPref ? ThemeMode.dark : ThemeMode.light;
  }

  static Future<void> setDarkMode(bool isDarkMode) async {
    themeNotifier.value = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyDarkMode, isDarkMode);
  }

  // Raw Palette Swatches (Constant brand colors for dark-surface elements)
  static const Color rawWhiteSmoke = Color(0xFFEFF1ED);
  static const Color rawDrySage = Color(0xFFBCBD8B);
  static const Color darkKhaki = Color(0xFF373D20);
  static const Color dustyOlive = Color(0xFF717744);
  static const Color ashBrown = Color(0xFF766153);

  // Adaptive Palette Swatches
  static Color get whiteSmoke =>
      isDark ? const Color(0xFFEFF1ED) : const Color(0xFF1B2117);
  static Color get drySage =>
      isDark ? const Color(0xFFBCBD8B) : const Color(0xFF555B30);

  // Semantic Design Tokens
  static Color get background =>
      isDark ? const Color(0xFF11140E) : const Color(0xFFF3F5EF);
  static Color get surface =>
      isDark ? const Color(0xFF1B2117) : const Color(0xFFFFFFFF);
  static Color get surfaceElevated =>
      isDark ? const Color(0xFF252D20) : const Color(0xFFE7EBE0);
  static const Color surfaceDarkKhaki = Color(0xFF373D20);
  static Color get inputFill =>
      isDark ? const Color(0xFF141811) : const Color(0xFFECF0E6);

  // Borders
  static Color get border =>
      isDark ? const Color(0x28BCBD8B) : const Color(0x38717744);
  static Color get borderFocused =>
      isDark ? const Color(0xFFBCBD8B) : const Color(0xFF717744);
  static Color get borderMuted =>
      isDark ? const Color(0x18EFF1ED) : const Color(0x181B2117);

  // Typography
  static Color get textPrimary =>
      isDark ? const Color(0xFFEFF1ED) : const Color(0xFF1B2117);
  static Color get textSecondary =>
      isDark ? const Color(0xFFA5AD9F) : const Color(0xFF525B4B);
  static Color get textMuted =>
      isDark ? const Color(0xFF6F7969) : const Color(0xFF7A8472);
  static const Color textOnAccent = Color(0xFF11140E);

  // Accents & Actions
  static const Color primary = Color(0xFF717744); // Dusty Olive
  static Color get accent => drySage;
  static const Color secondary = Color(0xFF766153); // Ash Brown
  static const Color warningRed = Color(0xFFA65858); // Muted terracotta rose
}
