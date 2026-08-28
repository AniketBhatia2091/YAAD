import 'package:flutter/material.dart';

class VaultCategory {
  final String key;
  final String title;
  final String description;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final int count;

  const VaultCategory({
    required this.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    this.count = 0,
  });
}
