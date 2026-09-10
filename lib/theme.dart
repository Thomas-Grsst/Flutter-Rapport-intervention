import 'package:flutter/material.dart';

/// Charte graphique reprise du rapport papier : bleu foncé pour les titres,
/// bleu clair pour les accents et les aplats.
class AppColors {
  const AppColors._();

  static const Color brandDark = Color(0xFF104C7E);
  static const Color brandLight = Color(0xFF8FB8E8);
  static const Color paleBlue = Color(0xFFEAF2FB);
  static const Color surface = Color(0xFFF6F8FB);
  static const Color success = Color(0xFF1F8A5B);
  static const Color warning = Color(0xFFC77700);
  static const Color danger = Color(0xFFB3261E);
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.brandDark,
    primary: AppColors.brandDark,
    surface: Colors.white,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.surface,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.brandDark,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE1E8F0)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD5DEE8)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD5DEE8)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.brandDark, width: 1.6),
      ),
      labelStyle: const TextStyle(color: Color(0xFF5A6773)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.brandDark,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 52),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.brandDark,
        minimumSize: const Size(0, 52),
        side: const BorderSide(color: AppColors.brandLight, width: 1.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    chipTheme: const ChipThemeData(
      side: BorderSide(color: Color(0xFFD5DEE8)),
      backgroundColor: Colors.white,
      selectedColor: AppColors.paleBlue,
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE1E8F0),
      space: 1,
      thickness: 1,
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
    ),
  );
}
