import 'package:flutter/material.dart';
import 'color_tokens.dart';

/// YAAD Design System — Typography Tokens
/// Generous spacing, readable sizes, strong hierarchy.
abstract class YaadTypography {
  static const String fontFamily = 'Roboto'; // Default Android readable sans-serif

  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    height: 1.2,
    letterSpacing: -0.5,
    color: YaadColors.textPrimaryLight,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.3,
    color: YaadColors.textPrimaryLight,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: -0.2,
    color: YaadColors.textPrimaryLight,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.35,
    color: YaadColors.textPrimaryLight,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: YaadColors.textPrimaryLight,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: YaadColors.textSecondaryLight,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: YaadColors.textSecondaryLight,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    color: YaadColors.textPrimaryLight,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
    color: YaadColors.textSecondaryLight,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.4,
    color: YaadColors.textMutedLight,
  );

  // ─── Dark Theme Typography (High Contrast Obsidian & Cream) ───────────────────

  static const TextStyle displayLargeDark = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    height: 1.2,
    letterSpacing: -0.5,
    color: YaadColors.textPrimaryDark,
  );

  static const TextStyle displayMediumDark = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.3,
    color: YaadColors.textPrimaryDark,
  );

  static const TextStyle titleLargeDark = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: -0.2,
    color: YaadColors.textPrimaryDark,
  );

  static const TextStyle titleMediumDark = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.35,
    color: YaadColors.textPrimaryDark,
  );

  static const TextStyle titleSmallDark = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: YaadColors.textPrimaryDark,
  );

  static const TextStyle bodyLargeDark = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: YaadColors.textSecondaryDark,
  );

  static const TextStyle bodyMediumDark = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: YaadColors.textSecondaryDark,
  );

  static const TextStyle labelLargeDark = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    color: YaadColors.textPrimaryDark,
  );

  static const TextStyle labelMediumDark = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
    color: YaadColors.textSecondaryDark,
  );

  static const TextStyle labelSmallDark = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.4,
    color: YaadColors.textMutedDark,
  );

  // ─── Adaptive Helpers (Adapts to Brightness) ──────────────────────────────────

  static TextStyle titleLargeOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? titleLargeDark : titleLarge;

  static TextStyle titleMediumOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? titleMediumDark : titleMedium;

  static TextStyle titleSmallOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? titleSmallDark : titleSmall;

  static TextStyle bodyMediumOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? bodyMediumDark : bodyMedium;

  static TextStyle labelMediumOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? labelMediumDark : labelMedium;

  static TextStyle labelSmallOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? labelSmallDark : labelSmall;
}
