import 'package:flutter/material.dart';

class AppColors {
  AppColors._();
  static const Color primary = Color(0xFF1A3D2B);
  static const Color primaryLight = Color(0xFF2E6B47);
  static const Color primaryDark = Color(0xFF0D2218);
  static const Color accent = Color(0xFF4CAF50);
  static const Color accentLight = Color(0xFF81C784);

  static const Color success = Color(0xFF2E7D32);
  static const Color error = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFF57C00);
  static const Color info = Color(0xFF1565C0);

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFE0E0E0);

  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  static const Color inputFill = Color(0xFFF5F5F5);
  static const Color inputBorder = Color(0xFFE0E0E0);
  static const Color inputFocusBorder = Color(0xFF1A3D2B);

  static const Color navBackground = Color(0xFF1A3D2B);
  static const Color navActive = Color(0xFF4CAF50);
  static const Color navInactive = Color(0xFF9E9E9E);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A3D2B), Color(0xFF2E6B47)],
  );
  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1A3D2B), Color(0xFF0D2218)],
  );
}
