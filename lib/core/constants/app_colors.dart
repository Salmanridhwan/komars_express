import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ─── Primary: Agri Green ──────────────────────────────────────────────────
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color primaryGreenLight = Color(0xFF4CAF50);
  static const Color primaryGreenSurface = Color(0xFFE8F5E9);
  static const Color primaryGreenDark = Color(0xFF1B5E20);

  // ─── Secondary: Express Amber-Orange ─────────────────────────────────────
  static const Color secondaryOrange = Color(0xFFEF6C00);
  static const Color secondaryOrangeLight = Color(0xFFFF9800);
  static const Color secondaryOrangeSurface = Color(0xFFFFF3E0);
  static const Color secondaryOrangeDark = Color(0xFFE65100);

  // ─── Category Badges ─────────────────────────────────────────────────────
  static const Color categoryFood = Color(0xFFEF6C00); // Orange
  static const Color categoryDrink = Color(0xFF1565C0); // Blue
  static const Color categoryBeverage = Color(0xFF2E7D32); // Green

  // ─── Status Colors ────────────────────────────────────────────────────────
  static const Color statusActive = Color(0xFF2196F3);
  static const Color statusSuccess = Color(0xFF4CAF50);
  static const Color statusPending = Color(0xFFFFC107);
  static const Color statusCancelled = Color(0xFFF44336);

  // ─── Light Theme ─────────────────────────────────────────────────────────
  static const Color lightBackground = Color(0xFFFAFAF8);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFF5F5F0);
  static const Color lightDivider = Color(0xFFE0E0E0);
  static const Color lightTextPrimary = Color(0xFF1A1A1A);
  static const Color lightTextSecondary = Color(0xFF757575);
  static const Color lightTextHint = Color(0xFFBDBDBD);

  // ─── Dark Theme ──────────────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCard = Color(0xFF2C2C2C);
  static const Color darkDivider = Color(0xFF3A3A3A);
  static const Color darkTextPrimary = Color(0xFFF5F5F5);
  static const Color darkTextSecondary = Color(0xFFAAAAAA);
  static const Color darkTextHint = Color(0xFF616161);

  // ─── Organic & Farm Tones ────────────────────────────────────────────────
  static const Color farmBadgeBg = Color(0xFFE8F5E9);
  static const Color farmBadgeText = Color(0xFF2E7D32);
  static const Color farmBadgeBorder = Color(0xFFA5D6A7);

  // ─── QRIS Screen ─────────────────────────────────────────────────────────
  static const Color qrisBlue = Color(0xFF0D47A1);
  static const Color qrisLightBlue = Color(0xFFE3F2FD);

  // ─── Swipe Delete ────────────────────────────────────────────────────────
  static const Color deleteRed = Color(0xFFD32F2F);
  static const Color deleteRedLight = Color(0xFFFFEBEE);

  // ─── Gradients ───────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
  );

  static const LinearGradient expressGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEF6C00), Color(0xFFFF9800)],
  );

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF388E3C)],
  );
}
