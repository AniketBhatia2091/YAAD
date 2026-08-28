import 'package:flutter/material.dart';

/// YAAD Design System — Elevation and Shadow Tokens
abstract class YaadShadows {
  static const List<BoxShadow> subtle = [
    BoxShadow(
      color: Color(0x0A0F172A),
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x0F0F172A),
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ];

  static const List<BoxShadow> captureButton = [
    BoxShadow(
      color: Color(0x38D97706),
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];
}
