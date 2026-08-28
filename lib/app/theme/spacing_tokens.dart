import 'package:flutter/material.dart';

/// YAAD Design System — Spacing Tokens
abstract class YaadSpacing {
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // Touch Target standard (48dp minimum for accessibility)
  static const double minTouchTarget = 48.0;

  // Insets helpers
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(horizontal: md, vertical: sm);
  static const EdgeInsets cardPadding = EdgeInsets.all(md);
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(horizontal: lg, vertical: md);
}
