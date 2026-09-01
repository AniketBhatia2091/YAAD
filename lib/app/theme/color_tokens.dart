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

  // YAAD Luxury Gold & Cream Accents
  static const Color goldPrimary = Color(0xFFD97706); // Deep Gold/Amber
  static const Color goldAccent = Color(0xFFF59E0B); // Vivid Amber Gold
  static const Color goldGlow = Color(0xFFFBBF24); // Warm Gold Glow
  static const Color goldSurface = Color(0x26D97706); // 15% Translucent Gold
  static const Color goldBorder = Color(0x40D97706); // 25% Gold Border
  static const Color creamText = Color(0xFFFDFBF7); // Warm Off-White Cream
  static const Color creamMuted = Color(0xFFD1C7B7); // Muted Warm Cream

  // Surface & Background (Light)
  static const Color backgroundLight = Color(0xFFF8FAF9); // Warm Sand Off-White
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceSubtleLight = Color(0xFFF1F5F9); // Slate 100
  static const Color borderLight = Color(0xFFE2E8F0); // Slate 200

  // Surface & Background (Dark — Obsidian Luxury Aesthetic)
  static const Color backgroundDark = Color(0xFF090D14); // Deep Obsidian Slate
  static const Color surfaceDark = Color(0xFF111722); // Card Surface
  static const Color surfaceRaised = Color(0xFF18202F); // Popover/Modal/Highlighted Card
  static const Color surfaceSubtleDark = Color(0xFF1B2332); // Slate Subtle Fill
  static const Color borderDark = Color(0xFF232D40); // Refined Dark Border
  static const Color borderGlass = Color(0x1FFFFFFF); // 12% Translucent Glass Outline
  static const Color glassCard = Color(0x0DFFFFFF); // 5% Subtle Glass Fill
  static const Color glassCardHover = Color(0x1AFFFFFF); // 10% Glass Fill

  // Typography Colors (Light)
  static const Color textPrimaryLight = Color(0xFF0F172A); // Slate 900
  static const Color textSecondaryLight = Color(0xFF475569); // Slate 600
  static const Color textMutedLight = Color(0xFF94A3B8); // Slate 400

  // Typography Colors (Dark)
  static const Color textPrimaryDark = Color(0xFFF8FAFC); // Crisp Off-White
  static const Color textSecondaryDark = Color(0xFF94A3B8); // Slate 400
  static const Color textMutedDark = Color(0xFF64748B); // Slate 500

  // Status & Actions
  static const Color attentionUrgent = Color(0xFFEF4444); // Red 500
  static const Color attentionUrgentBg = Color(0x26EF4444); // 15% Red
  static const Color attentionWarning = Color(0xFFF59E0B); // Amber 500
  static const Color attentionWarningBg = Color(0x26F59E0B); // 15% Amber
  static const Color attentionInfo = Color(0xFF38BDF8); // Sky 400
  static const Color attentionInfoBg = Color(0x2638BDF8); // 15% Sky
  static const Color success = Color(0xFF10B981); // Emerald 500
  static const Color successBg = Color(0x2610B981); // 15% Emerald

  // Category Accent Fills (Light & Dark Bento Palette)
  static const Color categoryIds = Color(0xFFE0E7FF); // Soft Indigo
  static const Color categoryIdsIcon = Color(0xFF6366F1);
  static const Color categoryIdsDarkBg = Color(0x1F6366F1);

  static const Color categoryBills = Color(0xFFFEF3C7); // Soft Amber
  static const Color categoryBillsIcon = Color(0xFFF59E0B);
  static const Color categoryBillsDarkBg = Color(0x1FF59E0B);

  static const Color categoryVehicles = Color(0xFFE0F2FE); // Soft Sky
  static const Color categoryVehiclesIcon = Color(0xFF38BDF8);
  static const Color categoryVehiclesDarkBg = Color(0x1F38BDF8);

  static const Color categoryMedical = Color(0xFFFCE7F3); // Soft Rose
  static const Color categoryMedicalIcon = Color(0xFFEC4899);
  static const Color categoryMedicalDarkBg = Color(0x1FEC4899);

  static const Color categoryWarranties = Color(0xFFDCFCE7); // Soft Emerald
  static const Color categoryWarrantiesIcon = Color(0xFF10B981);
  static const Color categoryWarrantiesDarkBg = Color(0x1F10B981);

  static const Color categoryEducation = Color(0xFFF3E8FF); // Soft Purple
  static const Color categoryEducationIcon = Color(0xFFA855F7);
  static const Color categoryEducationDarkBg = Color(0x1FA855F7);

  static const Color categoryUnsorted = Color(0xFFF1F5F9);
  static const Color categoryUnsortedIcon = Color(0xFFD97706);
  static const Color categoryUnsortedDarkBg = Color(0x1FD97706);
}
