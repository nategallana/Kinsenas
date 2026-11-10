import 'package:flutter/material.dart';

/// Kinsenas Earthy Botanical Design System
/// Palette inspired by:
/// - White Smoke (#EFF1ED)
/// - Dark Khaki (#373D20)
/// - Dusty Olive (#717744)
/// - Dry Sage (#BCBD8B)
/// - Ash Brown (#766153)
class AppColors {
  // Raw Palette Swatches
  static const Color whiteSmoke = Color(0xFFEFF1ED);
  static const Color darkKhaki = Color(0xFF373D20);
  static const Color dustyOlive = Color(0xFF717744);
  static const Color drySage = Color(0xFFBCBD8B);
  static const Color ashBrown = Color(0xFF766153);

  // Semantic Design Tokens
  static const Color background = Color(0xFF11140E); // Deep organic dark base
  static const Color surface = Color(0xFF1B2117);    // Primary card surface
  static const Color surfaceElevated = Color(0xFF252D20); // Secondary / elevated container
  static const Color surfaceDarkKhaki = Color(0xFF373D20); // Hero Goal Card from user sketch
  static const Color inputFill = Color(0xFF141811);  // Field backgrounds

  // Borders
  static const Color border = Color(0x28BCBD8B);      // Subtle Dry Sage 16% border
  static const Color borderFocused = Color(0xFFBCBD8B); // Focused border
  static const Color borderMuted = Color(0x18EFF1ED);

  // Typography
  static const Color textPrimary = Color(0xFFEFF1ED);   // Crisp White Smoke
  static const Color textSecondary = Color(0xFFA5AD9F); // Muted Sage
  static const Color textMuted = Color(0xFF6F7969);     // Tertiary / hints
  static const Color textOnAccent = Color(0xFF11140E);  // High contrast on Dry Sage

  // Accents & Actions
  static const Color primary = Color(0xFF717744);       // Dusty Olive
  static const Color accent = Color(0xFFBCBD8B);        // Dry Sage
  static const Color secondary = Color(0xFF766153);     // Ash Brown
  static const Color warningRed = Color(0xFFA65858);     // Muted terracotta rose for debts
}
