import 'package:flutter/material.dart';

/// Brand palette (skill.md §6).
class AppColors {
  const AppColors._();

  static const Color navy = Color(0xFF101B35);
  static const Color royalBlue = Color(0xFF2457D6);
  static const Color gold = Color(0xFFD8AE58);
  static const Color background = Color(0xFFF5F7FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color success = Color(0xFF16A36A);
  static const Color error = Color(0xFFDC3545);
  static const Color warning = Color(0xFFE59A1A);

  static const Color textPrimary = Color(0xFF101B35);
  static const Color textSecondary = Color(0xFF5E6B85);
  static const Color divider = Color(0xFFE3E8F2);

  // Dark theme surfaces.
  static const Color darkBackground = Color(0xFF0A1122);
  static const Color darkSurface = Color(0xFF141E38);
  static const Color darkSurfaceHigh = Color(0xFF1C2848);
  static const Color darkPrimary = Color(0xFF6F93F2);
  static const Color darkTextSecondary = Color(0xFF9AA6C2);

  /// Hero gradient for balance and account cards.
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [navy, Color(0xFF1B3275), royalBlue],
    stops: [0.0, 0.55, 1.0],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE9C987), gold, Color(0xFFB98C35)],
  );

  static const LinearGradient savingsGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F3D3A), Color(0xFF16735F), success],
  );
}
