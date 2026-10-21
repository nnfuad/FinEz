import 'package:flutter/material.dart';

/// Spotify-inspired dark theme color palette for FinEz
class AppColors {
  AppColors._();

  // Core Surfaces
  static const Color background = Color(0xFF121212);
  static const Color navigationSurface = Color(0xFF000000);
  static const Color card = Color(0xFF181818);
  static const Color elevated = Color(0xFF242424);
  static const Color border = Color(0xFF2E2E2E);

  // Accents
  static const Color primary = Color(0xFF1ED760); // Spotify Green
  static const Color primaryVariant = Color(0xFF169C46);
  static const Color onPrimary = Color(0xFF000000);

  // Typography
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB3B3B3);
  static const Color textMuted = Color(0xFF757575);

  // Status Colors
  static const Color statusPaid = Color(0xFF1ED760); // Green
  static const Color statusDue = Color(0xFFFF5252); // Red/Orange
  static const Color statusPartial = Color(0xFFFFB300); // Amber
  static const Color statusWaived = Color(0xFF757575); // Neutral Gray

  // Balance & Ledger Accents
  static const Color inflow = Color(0xFF1ED760);
  static const Color outflow = Color(0xFFFF5252);
  static const Color transfer = Color(0xFF29B6F6);
}
