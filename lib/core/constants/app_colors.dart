import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ─── Primary: Express Orange (digunakan di seluruh aplikasi) ─────────────
  static const Color primaryGreen = Color(0xFFEF6C00);        // alias → oranye
  static const Color primaryGreenLight = Color(0xFFFF9800);   // oranye muda
  static const Color primaryGreenSurface = Color(0xFFFFF3E0); // latar oranye lembut
  static const Color primaryGreenDark = Color(0xFFE65100);    // oranye gelap

  // ─── Secondary: Express Amber-Orange (identik, satu warna sistem) ────────
  static const Color secondaryOrange = Color(0xFFEF6C00);
  static const Color secondaryOrangeLight = Color(0xFFFF9800);
  static const Color secondaryOrangeSurface = Color(0xFFFFF3E0);
  static const Color secondaryOrangeDark = Color(0xFFE65100);

  // ─── Category Badges ─────────────────────────────────────────────────────
  static const Color categoryFood = Color(0xFFEF6C00);     // Orange
  static const Color categoryDrink = Color(0xFFFF8F00);    // Amber
  static const Color categoryBeverage = Color(0xFFE65100); // Deep Orange

  // ─── Status Colors ────────────────────────────────────────────────────────
  static const Color statusActive = Color(0xFF2196F3);
  static const Color statusSuccess = Color(0xFF4CAF50);
  static const Color statusPending = Color(0xFFFFC107);
  static const Color statusCancelled = Color(0xFFF44336);

  // ─── Light Theme ─────────────────────────────────────────────────────────
  static const Color lightBackground = Color(0xFFFFFAF5);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFF3E0);
  static const Color lightDivider = Color(0xFFFFE0B2);
  static const Color lightTextPrimary = Color(0xFF1A1A1A);
  static const Color lightTextSecondary = Color(0xFF757575);
  static const Color lightTextHint = Color(0xFFBDBDBD);

  // ─── Dark Theme ──────────────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF1A0F00);
  static const Color darkSurface = Color(0xFF2A1A08);
  static const Color darkCard = Color(0xFF3A2412);
  static const Color darkDivider = Color(0xFF4A3020);
  static const Color darkTextPrimary = Color(0xFFF5F5F5);
  static const Color darkTextSecondary = Color(0xFFAAAAAA);
  static const Color darkTextHint = Color(0xFF616161);

  // ─── Farm / Agri tones → tetap oranye untuk konsistensi ─────────────────
  static const Color farmBadgeBg = Color(0xFFFFF3E0);
  static const Color farmBadgeText = Color(0xFFEF6C00);
  static const Color farmBadgeBorder = Color(0xFFFFCC80);

  // ─── QRIS Screen ─────────────────────────────────────────────────────────
  static const Color qrisBlue = Color(0xFF0D47A1);
  static const Color qrisLightBlue = Color(0xFFE3F2FD);

  // ─── Swipe Delete ────────────────────────────────────────────────────────
  static const Color deleteRed = Color(0xFFD32F2F);
  static const Color deleteRedLight = Color(0xFFFFEBEE);

  // ─── Gradients ───────────────────────────────────────────────────────────
  // Primary (Farm & Express) — semua oranye
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEF6C00), Color(0xFFFF9800)],
  );

  // Express header gradient
  static const LinearGradient expressGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE65100), Color(0xFFFF9800)],
  );

  // Splash gradient — oranye hangat
  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFBF360C), Color(0xFFEF6C00), Color(0xFFFF9800)],
  );
}
