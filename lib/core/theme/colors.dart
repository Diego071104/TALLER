import 'package:flutter/material.dart';

/// Medical-monitor inspired palette: deep navy background, cyan/teal data,
/// red for critical, amber for warnings, green for nominal states.
///
/// Calibrated for OLED-friendly dark viewing during demos.
class AppColors {
  AppColors._();

  static const background = Color(0xFF06121C);
  static const surface = Color(0xFF0E1F2E);
  static const surfaceElevated = Color(0xFF14283B);
  static const divider = Color(0xFF1E3A52);

  static const textPrimary = Color(0xFFE6F1FB);
  static const textSecondary = Color(0xFF8BA9C0);
  static const textMuted = Color(0xFF5A7891);

  static const accentCyan = Color(0xFF22D3EE);
  static const accentTeal = Color(0xFF14B8A6);
  static const accentGreen = Color(0xFF34D399);
  static const accentAmber = Color(0xFFFBBF24);
  static const accentRed = Color(0xFFEF4444);
  static const accentMagenta = Color(0xFFE879F9);

  static const ecgLine = Color(0xFF22D3EE);
  static const ecgGrid = Color(0xFF1E3A52);
  static const ecgGridMajor = Color(0xFF2A4F6E);

  static const zoneRest = Color(0xFF60A5FA);
  static const zoneFatBurn = Color(0xFF34D399);
  static const zoneAerobic = Color(0xFFFBBF24);
  static const zoneAnaerobic = Color(0xFFFB923C);
  static const zoneMax = Color(0xFFEF4444);

  static const success = accentGreen;
  static const warning = accentAmber;
  static const danger = accentRed;
}
