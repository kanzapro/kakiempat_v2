import 'package:flutter/material.dart';

/// Warna brand Kaki Empat v2 — hangat, segar, ramah.
abstract final class AppColors {
  static const Color primary = Color(0xFF2E7D32);
  static const Color primaryLight = Color(0xFF4CAF50);
  static const Color primaryDark = Color(0xFF1B5E20);
  static const Color accent = Color(0xFFFF8F00);
  static const Color accentWarm = Color(0xFFFF9800);
  static const Color offerGreen = Color(0xFF43A047);
  static const Color surfaceWarm = Color(0xFFFAFAFA);
  static const Color cream = Color(0xFFFFF8E1);

  static Color statusSuccess(ColorScheme scheme) => primary;

  static Color statusWarning(ColorScheme scheme) => accentWarm;

  static Color statusInfo(ColorScheme scheme) => const Color(0xFF1976D2);

  static Color statusError(ColorScheme scheme) => scheme.error;

  static Color statusNeutral(ColorScheme scheme) => scheme.onSurfaceVariant;

  static Color statusProgress(ColorScheme scheme) =>
      Color.lerp(primary, primaryLight, 0.5) ?? primary;

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFE8F5E9), cream],
  );

  static const LinearGradient sitterHeroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE8F5E9), Color(0xFFFFF3E0)],
  );
}
