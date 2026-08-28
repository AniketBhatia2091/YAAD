import 'package:flutter/material.dart';
import 'color_tokens.dart';
import 'radius_tokens.dart';
import 'spacing_tokens.dart';
import 'typography_tokens.dart';

/// Centralized ThemeData builder for YAAD Custom Visual System
abstract class YaadTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: YaadColors.primary,
      scaffoldBackgroundColor: YaadColors.backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: YaadColors.primary,
        onPrimary: Colors.white,
        secondary: YaadColors.accent,
        onSecondary: Colors.white,
        surface: YaadColors.surfaceLight,
        onSurface: YaadColors.textPrimaryLight,
        surfaceContainerHighest: YaadColors.surfaceSubtleLight,
        outline: YaadColors.borderLight,
        error: YaadColors.attentionUrgent,
      ),
      fontFamily: YaadTypography.fontFamily,
      appBarTheme: const AppBarTheme(
        backgroundColor: YaadColors.backgroundLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: YaadColors.textPrimaryLight, size: 24),
        titleTextStyle: YaadTypography.titleLarge,
      ),
      cardTheme: const CardThemeData(
        color: YaadColors.surfaceLight,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: YaadRadius.borderLg,
          side: BorderSide(color: YaadColors.borderLight, width: 1),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: YaadColors.surfaceSubtleLight,
        contentPadding: EdgeInsets.symmetric(
          horizontal: YaadSpacing.md,
          vertical: YaadSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: YaadRadius.borderMd,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: YaadRadius.borderMd,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: YaadRadius.borderMd,
          borderSide: BorderSide(color: YaadColors.accent, width: 1.5),
        ),
        hintStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: YaadColors.textMutedLight,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: YaadColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, YaadSpacing.minTouchTarget),
          padding: YaadSpacing.buttonPadding,
          shape: const RoundedRectangleBorder(
            borderRadius: YaadRadius.borderMd,
          ),
          textStyle: YaadTypography.labelLarge.copyWith(color: Colors.white),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: YaadColors.textPrimaryLight,
          minimumSize: const Size(double.infinity, YaadSpacing.minTouchTarget),
          padding: YaadSpacing.buttonPadding,
          side: const BorderSide(color: YaadColors.borderLight, width: 1.5),
          shape: const RoundedRectangleBorder(
            borderRadius: YaadRadius.borderMd,
          ),
          textStyle: YaadTypography.labelLarge,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: YaadColors.surfaceLight,
        selectedItemColor: YaadColors.primary,
        unselectedItemColor: YaadColors.textMutedLight,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: YaadTypography.labelSmall,
        unselectedLabelStyle: YaadTypography.labelSmall,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: YaadColors.accent,
      scaffoldBackgroundColor: YaadColors.backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: YaadColors.accent,
        onPrimary: Colors.black,
        secondary: YaadColors.accent,
        onSecondary: Colors.black,
        surface: YaadColors.surfaceDark,
        onSurface: YaadColors.textPrimaryDark,
        surfaceContainerHighest: YaadColors.surfaceSubtleDark,
        outline: YaadColors.borderDark,
        error: YaadColors.attentionUrgent,
      ),
      fontFamily: YaadTypography.fontFamily,
      appBarTheme: const AppBarTheme(
        backgroundColor: YaadColors.backgroundDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: YaadColors.textPrimaryDark, size: 24),
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: YaadColors.textPrimaryDark,
        ),
      ),
      cardTheme: const CardThemeData(
        color: YaadColors.surfaceDark,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: YaadRadius.borderLg,
          side: BorderSide(color: YaadColors.borderDark, width: 1),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: YaadColors.surfaceSubtleDark,
        contentPadding: EdgeInsets.symmetric(
          horizontal: YaadSpacing.md,
          vertical: YaadSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: YaadRadius.borderMd,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: YaadRadius.borderMd,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: YaadRadius.borderMd,
          borderSide: BorderSide(color: YaadColors.accent, width: 1.5),
        ),
        hintStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: YaadColors.textMutedDark,
        ),
      ),
    );
  }
}
