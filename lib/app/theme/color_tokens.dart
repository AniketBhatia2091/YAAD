import 'package:flutter/material.dart';

/// YAAD Design System — Color Tokens
/// Modern, trustworthy, calm, Indian-market friendly color palette.
abstract class YaadColors {
  // Brand Primary & Accent
  static const Color primary = Color(0xFF0F172A); // Slate 900 — Deep, authoritative, calm
  static const Color primaryLight = Color(0xFF1E293B); // Slate 800
  static const Color accent = Color(0xFFD97706); // Warm Amber/Copper — Inviting, distinct accent
  static const Color accentLight = Color(0xFFFEF3C7); // Warm Amber Soft Fill
  static const Color brandIndigo = Color(0xFF4338CA); // Deep Indian Indigo accent for subtle highlights

  // Surface & Background (Light)
  static const Color backgroundLight = Color(0xFFF8FAF9); // Warm Sand Off-White
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceSubtleLight = Color(0xFFF1F5F9); // Slate 100
  static const Color borderLight = Color(0xFFE2E8F0); // Slate 200

  // Surface & Background (Dark)
  static const Color backgroundDark = Color(0xFF0B0F17); // Dark Charcoal
  static const Color surfaceDark = Color(0xFF151C28);
  static const Color surfaceSubtleDark = Color(0xFF1E293B);
  static const Color borderDark = Color(0xFF334155);

  // Typography Colors (Light)
  static const Color textPrimaryLight = Color(0xFF0F172A); // Slate 900
  static const Color textSecondaryLight = Color(0xFF475569); // Slate 600
  static const Color textMutedLight = Color(0xFF94A3B8); // Slate 400

  // Typography Colors (Dark)
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textMutedDark = Color(0xFF64748B);

  // Status & Actions
  static const Color attentionUrgent = Color(0xFFDC2626); // Red 600
  static const Color attentionUrgentBg = Color(0xFFFEE2E2);
  static const Color attentionWarning = Color(0xFFD97706); // Amber 600
  static const Color attentionWarningBg = Color(0xFFFEF3C7);
  static const Color attentionInfo = Color(0xFF2563EB); // Blue 600
  static const Color attentionInfoBg = Color(0xFFDBEAFE);
  static const Color success = Color(0xFF166534); // Emerald 800
  static const Color successBg = Color(0xFFDCFCE7);

  // Category Accent Fills (for Vault)
  static const Color categoryIds = Color(0xFFE0E7FF); // Soft Indigo
  static const Color categoryIdsIcon = Color(0xFF4338CA);
  static const Color categoryBills = Color(0xFFFEF3C7); // Soft Amber
  static const Color categoryBillsIcon = Color(0xFFB45309);
  static const Color categoryVehicles = Color(0xFFE0F2FE); // Soft Sky
  static const Color categoryVehiclesIcon = Color(0xFF0369A1);
  static const Color categoryMedical = Color(0xFFFCE7F3); // Soft Rose
  static const Color categoryMedicalIcon = Color(0xFFBE185D);
  static const Color categoryWarranties = Color(0xFFDCFCE7); // Soft Emerald
  static const Color categoryWarrantiesIcon = Color(0xFF15803D);
  static const Color categoryEducation = Color(0xFFF3E8FF); // Soft Purple
  static const Color categoryEducationIcon = Color(0xFF7E22CE);
}
