import 'package:flutter/material.dart';

class VinciTheme {
  // Primary palette from wireframes
  static const primary = Color(0xFF667EEA);
  static const primaryDark = Color(0xFF764BA2);
  static const secondary = Color(0xFF764BA2);

  static const backgroundLight = Color(0xFFF0F2F8);
  static const backgroundGradientEnd = Color(0xFFE2E7F0);
  static const backgroundMain = Color(0xFFF8F9FC);

  static const cardBackground = Colors.white;
  static const borderColor = Color(0xFFF0F2F8);

  static const iconPanelGradientStart = Color(0xFFFAFBFF);
  static const iconPanelGradientEnd = Color(0xFFF5F7FC);

  static const textPrimary = Color(0xFF1A1A3E);
  static const textSecondary = Color(0xFF8A8AA3);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
        surface: cardBackground,
      ),
      scaffoldBackgroundColor: backgroundMain,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardTheme(
        color: cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderColor, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
      ),
    );
  }
}
