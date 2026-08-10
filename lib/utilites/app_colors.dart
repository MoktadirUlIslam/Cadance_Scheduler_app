// lib/utilites/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // Primary - Teal
  static const Color primaryLight = Color(0xFF0F6E56);
  static const Color primaryDark = Color(0xFF3CB891);
  static const Color primaryDeep = Color(0xFF0A4A3A);
  static const Color primaryTint = Color(0xFF5DCAA5);

  // Secondary - Warm Coral
  static const Color accentLight = Color(0xFFD85A30);
  static const Color accentDark = Color(0xFFF0997B);

  // Success - Soft Green
  static const Color successLight = Color(0xFF639922);
  static const Color successDark = Color(0xFF97C459);

  // Warning - Amber
  static const Color warningLight = Color(0xFFBA7517);
  static const Color warningDark = Color(0xFFEF9F27);

  // Purple
  static const Color purple = Color(0xFF7F77DD);

  // Light mode neutrals
  static const Color bg = Color(0xFFF7F7F5);
  static const Color card = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF0E241E);
  static const Color inkSoft = Color(0xFF6B7C76);
  static const Color border = Color(0xFFE7E7E1);

  // Dark mode neutrals
  static const Color darkBg = Color(0xFF121210);
  static const Color darkCard = Color(0xFF1E1E1B);
  static const Color darkInk = Color(0xFFE8E8E5);
  static const Color darkInkSoft = Color(0xFF9A9A94);
  static const Color darkBorder = Color(0xFF2E2E2B);

  // Dark mode surface colors
  static const Color darkSurface = Color(0xFF252525);
  static const Color darkSurfaceVariant = Color(0xFF2D2D2D);
}

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: AppColors.bg,
  colorScheme: const ColorScheme.light(
    primary: AppColors.primaryLight,
    secondary: AppColors.accentLight,
    surface: Colors.white,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: AppColors.ink,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.bg,
    elevation: 0,
    iconTheme: IconThemeData(color: AppColors.ink),
    titleTextStyle: TextStyle(
      color: AppColors.ink,
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
  ),
  cardTheme: CardThemeData(
    color: AppColors.card,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: AppColors.border),
    ),
  ),
  dividerColor: AppColors.border,
  hintColor: AppColors.inkSoft,
);

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: AppColors.darkBg,
  colorScheme: const ColorScheme.dark(
    primary: AppColors.primaryDark,
    secondary: AppColors.accentDark,
    surface: AppColors.darkCard,
    onPrimary: AppColors.darkBg,
    onSecondary: AppColors.darkBg,
    onSurface: AppColors.darkInk,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.darkBg,
    elevation: 0,
    iconTheme: IconThemeData(color: AppColors.darkInk),
    titleTextStyle: TextStyle(
      color: AppColors.darkInk,
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
  ),
  cardTheme: CardThemeData(
    color: AppColors.darkCard,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: AppColors.darkBorder),
    ),
  ),
  dividerColor: AppColors.darkBorder,
  hintColor: AppColors.darkInkSoft,
);