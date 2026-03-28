import 'package:flutter/material.dart';

/// Палитра «Незнакомец» (только тёмная тема).
abstract final class NeznakometsColors {
  static const Color background = Color(0xFF0D0D0D);
  static const Color card = Color(0xFF161616);
  static const Color accent = Color(0xFFC8B8FF);
  static const Color bubbleAi = Color(0xFF1A1A1A);
  static const Color bubbleUser = Color(0xFF2A1F4A);
  static const Color textPrimary = Color(0xFFE8E8E8);
  static const Color textSecondary = Color(0xFF555555);
}

abstract final class NeznakometsTheme {
  static ThemeData get dark {
    const primary = NeznakometsColors.accent;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: NeznakometsColors.background,
      colorScheme: const ColorScheme.dark(
        surface: NeznakometsColors.card,
        primary: primary,
        onPrimary: Color(0xFF0D0D0D),
        secondary: primary,
        onSecondary: Color(0xFF0D0D0D),
        onSurface: NeznakometsColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: NeznakometsColors.card,
        foregroundColor: NeznakometsColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: const CardThemeData(
        color: NeznakometsColors.card,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: NeznakometsColors.textSecondary,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(
          fontSize: 15,
          height: 1.4,
          color: NeznakometsColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 15,
          height: 1.4,
          color: NeznakometsColors.textPrimary,
        ),
        bodySmall: TextStyle(
          fontSize: 15,
          color: NeznakometsColors.textSecondary,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: NeznakometsColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: NeznakometsColors.textPrimary,
        ),
        labelLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: NeznakometsColors.textPrimary,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Color(0xFF0D0D0D),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: NeznakometsColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: NeznakometsColors.textSecondary),
      ),
    );
  }
}
