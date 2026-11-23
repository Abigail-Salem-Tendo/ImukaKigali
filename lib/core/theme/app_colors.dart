import 'package:flutter/material.dart';

/// Every colour in the app lives here
/// Screens use Theme.of(context).colorScheme for normal UI.
/// Only [success] is read straight from here.
class AppColors {
  AppColors._();

  // light theme
  static const Color lightPrimary = Color(0xFF00A1DE);
  static const Color lightOnPrimary = Color(0xFFFFFFFF);
  static const Color lightSecondary = Color(0xFFFAD201);
  static const Color lightOnSecondary = Color(
    0xFF1C1C1E,
  ); // dark text on yellow
  static const Color lightBackground = Color(0xFFF7F8FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF1C1C1E);
  static const Color lightTextSecondary = Color(0xFF6B7280);
  static const Color lightBorder = Color(0xFFE5E7EB);
  static const Color lightError = Color(0xFFD32F2F);

  // dark theme
  static const Color darkPrimary = Color(0xFF00A1DE);
  static const Color darkOnPrimary = Color(0xFFFFFFFF);
  static const Color darkSecondary = Color(0xFFFAD201);
  static const Color darkOnSecondary = Color(0xFF1C1C1E);
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkText = Color(0xFFF5F5F5);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);
  static const Color darkBorder = Color(0xFF3A3A3C);
  static const Color darkError = Color(0xFFEF5350);

  // used by both the light and dark themes
  static const Color success = Color(0xFF2E7D32);
}
