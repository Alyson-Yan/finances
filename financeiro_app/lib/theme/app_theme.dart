import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF050816);

  static const surface = Color(0xFF101827);
  static const surfaceLight = Color(0xFF172033);
  static const surfaceSoft = Color(0xFF0B1220);

  static const primaryBlue = Color(0xFF2563EB);
  static const accentBlue = Color(0xFF38BDF8);

  static const success = Color(0xFF22C55E);
  static const danger = Color(0xFFFF4D4D);
  static const warning = Color(0xFFFFB020);

  static const textPrimary = Color(0xFFF8FAFC);
  static const textSecondary = Color(0xFF9CA3AF);
  static const textMuted = Color(0xFF64748B);

  static const border = Color(0xFF1F2A3D);
}

class AppTheme {
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    scaffoldBackgroundColor: AppColors.background,
    primaryColor: AppColors.primaryBlue,

    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryBlue,
      secondary: AppColors.accentBlue,
      surface: AppColors.surface,
      error: AppColors.danger,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
    ),

    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(
          color: AppColors.border,
          width: 1,
        ),
      ),
      margin: EdgeInsets.zero,
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primaryBlue,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: CircleBorder(),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: 22,
          vertical: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      hintStyle: const TextStyle(
        color: AppColors.textSecondary,
      ),
      labelStyle: const TextStyle(
        color: AppColors.textSecondary,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: AppColors.border,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: AppColors.border,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: AppColors.accentBlue,
          width: 1.5,
        ),
      ),
    ),

    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 32,
        fontWeight: FontWeight.w800,
      ),
      headlineMedium: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 24,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
      ),
      bodyMedium: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 14,
      ),
      bodySmall: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12,
      ),
    ),
  );
}